#!/usr/bin/env bash
# run-cases.sh: deploy each case in cases.json with func, and check what the
# cluster built against what the case expects. See README.md, "Test cases".
set -uo pipefail

usage() {
  cat <<'EOF'
Usage: ./run-cases.sh --registry <registry> [flags] [case-id glob...]

Deploys each case of cases.json with `func deploy --remote --source ...` and
checks it. With globs, only the cases whose id matches one of them.

Flags:
  --func <path>       the func binary (default: func on PATH)
  --registry <reg>    the registry for {registry} (required)
  --namespace <ns>    the namespace for {namespace} (default: func-test)
  --url <url>         the repository (default: "repository" in cases.json)
  --insecure          add --registry-insecure to every deploy (plain-HTTP registry)
  --skip <req>        skip the cases that require <req> (repeatable): keda, disk,
                      kind-registry, namespace:func-test-pinned
  --keep              keep what each case deployed
  --kind-node <name>  the container of a kind node (e.g. func-control-plane):
                      after each deploy, also remove the function's image from
                      it, and log the node's free disk
  --out <dir>         where to write the logs (default: runs/<time>)

The namespaces must exist, with the rights the pipeline needs to deploy there:
<ns>, and func-test-pinned for the cases that require it. KUBECONFIG selects
the cluster. Needs git, jq, kubectl and curl; skopeo to check image labels.
EOF
}

here=$(cd "$(dirname "$0")" && pwd)
FUNC=func REGISTRY= NS=func-test URL= INSECURE= KEEP= OUT= NODE=
SKIP=() GLOBS=()
while [ $# -gt 0 ]; do
  case $1 in
    --func) FUNC=$2; shift 2 ;;
    --registry) REGISTRY=$2; shift 2 ;;
    --namespace) NS=$2; shift 2 ;;
    --url) URL=$2; shift 2 ;;
    --insecure) INSECURE=1; shift ;;
    --skip) SKIP+=("$2"); shift 2 ;;
    --keep) KEEP=1; shift ;;
    --kind-node) NODE=$2; shift 2 ;;
    --out) OUT=$2; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    -*) echo "unknown flag: $1" >&2; usage >&2; exit 2 ;;
    *) GLOBS+=("$1"); shift ;;
  esac
done
[ -n "$REGISTRY" ] || { echo "--registry is required" >&2; exit 2; }
for t in git jq kubectl curl; do
  command -v $t >/dev/null || { echo "$t not found" >&2; exit 2; }
done
FUNC=$(command -v "$FUNC") || { echo "func binary not found" >&2; exit 2; }
CASES=$here/cases.json
[ -n "$URL" ] || URL=$(jq -r .repository "$CASES")
OUT=${OUT:-$here/runs/$(date +%Y%m%d-%H%M%S)}
mkdir -p "$OUT"
kubectl get ns "$NS" >/dev/null 2>&1 || { echo "namespace $NS does not exist" >&2; exit 2; }

# The repository's refs, once: "<hash> <ref>" per line, peeled tags as <ref>^{}.
REFS=$OUT/refs.txt
git ls-remote "$URL" > "$REFS" || { echo "cannot list the refs of $URL" >&2; exit 2; }

# resolve <ref>: the full commit hash <ref> names, picked as func picks it: a
# full ref name as given, otherwise a tag before a branch; a full hash as is.
resolve() {
  local r=$1 n c
  if [[ $r =~ ^[0-9a-f]{40}$ ]]; then echo "$r"; return; fi
  local names=("refs/tags/$r" "refs/heads/$r")
  [[ $r == refs/* ]] && names=("$r")
  for n in "${names[@]}"; do
    c=$(awk -v n="$n^{}" '$2 == n { print $1 }' "$REFS")
    [ -n "$c" ] || c=$(awk -v n="$n" '$2 == n { print $1 }' "$REFS")
    [ -n "$c" ] && { echo "$c"; return; }
  done
}

# subst <text>: <text> with the placeholders filled in.
subst() {
  local s=$1 h
  s=${s//\{registry\}/$REGISTRY}
  s=${s//\{namespace\}/$NS}
  s=${s//\{url\}/$URL}
  while [[ $s =~ \{(commit|short):([^}]*)\} ]]; do
    h=$(resolve "${BASH_REMATCH[2]}")
    [ "${BASH_REMATCH[1]}" = short ] && h=${h:0:7}
    s=${s/"${BASH_REMATCH[0]}"/$h}
  done
  printf '%s' "$s"
}

# unmet <requirement>: why the cluster lacks it; nothing when it has it.
unmet() {
  local r=$1 s
  for s in "${SKIP[@]}"; do
    [ "$s" = "$r" ] && { echo "skipped (--skip $r)"; return; }
  done
  case $r in
    keda) kubectl get crd httpscaledobjects.http.keda.sh >/dev/null 2>&1 || echo "no KEDA HTTP add-on" ;;
    namespace:*) kubectl get ns "${r#namespace:}" >/dev/null 2>&1 || echo "no namespace ${r#namespace:}" ;;
  esac
}

# clean <name> <ns> [image]: remove the function and what its builds left:
# the next build from git on the same PVC fails otherwise (the clone cannot
# empty it). With --kind-node, also the function's image from the node, once
# no pod runs it any more.
clean() {
  "$FUNC" delete "$1" -n "$2" >/dev/null 2>&1
  kubectl delete pipelinerun,pvc -n "$2" -l "function.knative.dev/name=$1" --wait=true >/dev/null 2>&1
  [ -n "$NODE" ] && [ -n "${3:-}" ] || return 0
  local _
  for _ in $(seq 1 20); do
    docker exec "$NODE" crictl rmi "${3/:latest@/@}" >/dev/null 2>&1 && return 0
    docker exec "$NODE" crictl inspecti "${3/:latest@/@}" >/dev/null 2>&1 || return 0
    sleep 3
  done
  echo "could not remove $3 from $NODE" >> "$log"
}

# get <url>: what the function answers, from inside the cluster.
get() {
  kubectl exec -n "$NS" func-test-curl -- curl -sS -m 10 "$1" 2>&1
}

CURL_POD=
curlpod() {
  [ -n "$CURL_POD" ] && return
  kubectl run func-test-curl -n "$NS" --image=curlimages/curl --restart=Never \
    --command -- sleep infinity >/dev/null 2>&1
  kubectl wait -n "$NS" pod/func-test-curl --for=condition=Ready --timeout=180s >/dev/null
  CURL_POD=1
}
trap '[ -z "$CURL_POD" ] || kubectl delete pod -n "$NS" func-test-curl --wait=false >/dev/null 2>&1' EXIT

pass=0 fail=0 skip=0 nknown=0
echo "func:       $FUNC"
echo "repository: $URL"
echo "registry:   $REGISTRY    namespace: $NS    logs: $OUT"
echo

while IFS= read -r c; do
  id=$(jq -r .id <<<"$c")
  if [ ${#GLOBS[@]} -gt 0 ]; then
    m=; for g in "${GLOBS[@]}"; do [[ $id == $g ]] && m=1; done
    [ -n "$m" ] || continue
  fi
  log=$OUT/$id.log
  why=
  while IFS= read -r r; do
    [ -n "$r" ] || continue
    why=$(unmet "$r"); [ -n "$why" ] && break
  done < <(jq -r '.requires[]?' <<<"$c")
  if [ -n "$why" ]; then
    printf 'SKIP   %-36s %s\n' "$id" "$why"; skip=$((skip + 1)); continue
  fi

  # The command.
  envs=()
  while IFS= read -r e; do
    [ -n "$e" ] && envs+=("$(subst "$e")")
  done < <(jq -r '.env // {} | to_entries[] | "\(.key)=\(.value)"' <<<"$c")
  argv=(deploy --remote)
  src=$URL
  frag=$(jq -r '.fragment // empty' <<<"$c")
  [ -n "$frag" ] && src="$URL#$frag"
  jq -e '.env.FUNC_SOURCE' <<<"$c" >/dev/null || argv+=(--source "$src")
  dir=$(jq -r '.dir // empty' <<<"$c")
  [ -n "$dir" ] && argv+=(--source-dir "$dir")
  rev=$(jq -r '.revision // empty' <<<"$c")
  [ -n "$rev" ] && argv+=(--revision "$(subst "$rev")")
  while IFS= read -r a; do
    argv+=("$(subst "$a")")
  done < <(jq -r '.args[]?' <<<"$c")
  [ -n "$INSECURE" ] && argv+=(--registry-insecure)

  err=$(jq -r '.expect.error // empty' <<<"$c")
  name=$(jq -r '.expect.name // empty' <<<"$c")
  ns=$(subst "$(jq -r '.expect.namespace // "{namespace}"' <<<"$c")")
  image=
  [ -n "$name" ] && clean "$name" "$ns"
  prs_before=$(kubectl get pipelinerun -A -o name 2>/dev/null | sort)

  work=$(mktemp -d)
  {
    echo "case: $c"
    printf 'command: cd %s &&' "$work"
    for e in "${envs[@]}"; do printf ' %q' "$e"; done
    printf ' %q' "$FUNC" "${argv[@]}"; echo; echo
  } > "$log"
  t0=$(date +%s)
  (cd "$work" && timeout 20m env "${envs[@]}" "$FUNC" "${argv[@]}") >> "$log" 2>&1
  rc=$?
  secs=$(( $(date +%s) - t0 ))
  echo "exit: $rc (${secs}s)" >> "$log"

  fails=()
  left=$(ls -A "$work")
  [ -z "$left" ] || fails+=("wrote locally: $(echo $left)")
  rm -rf "$work"

  if [ -n "$err" ]; then
    [ $rc -ne 0 ] || fails+=("deploy succeeded, expected an error")
    grep -qF -- "$err" "$log" || fails+=("no \"$err\" in the output")
    new=$(comm -13 <(echo "$prs_before") <(kubectl get pipelinerun -A -o name 2>/dev/null | sort))
    [ -z "$new" ] || fails+=("a PipelineRun started: $(echo $new)")
  else
    if [ $rc -ne 0 ]; then
      fails+=("deploy failed: $(grep -m1 -E '^Error' "$log" | cut -c1-160)")
    else
      want=$(resolve "$(jq -r .expect.commit <<<"$c")")
      pr=$(kubectl get pipelinerun -n "$ns" -l "function.knative.dev/name=$name" \
        --sort-by=.metadata.creationTimestamp -o name 2>/dev/null | tail -1)
      if [ -z "$pr" ]; then
        fails+=("no PipelineRun for $name in $ns")
      else
        prj=$(kubectl get -n "$ns" "$pr" -o json)
        param() { jq -r --arg n "$1" '.spec.params[] | select(.name == $n) | .value' <<<"$prj"; }
        [ "$(param gitRevision)" = "$want" ] || fails+=("gitRevision $(param gitRevision), want $want")
        [ "$(param commit)" = "${want:0:7}" ] || fails+=("commit label param $(param commit), want ${want:0:7}")
        img=$(subst "$(jq -r '.expect.image // empty' <<<"$c")")
        [ -z "$img" ] || [[ $(param imageName) == "$img"* ]] || fails+=("imageName $(param imageName), want $img...")
        b=$(jq -r '.expect.builder // empty' <<<"$c")
        [ -z "$b" ] || [[ $(jq -r .spec.pipelineRef.name <<<"$prj") == *-$b-git ]] \
          || fails+=("pipeline $(jq -r .spec.pipelineRef.name <<<"$prj"), want builder $b")
        tr=$(kubectl get taskrun -n "$ns" -l "tekton.dev/pipelineRun=${pr#*/}" -o name | head -1)
        got=$(kubectl get -n "$ns" "$tr" -o json | jq -r '.status.steps[]? | select(.name == "fetch-src") | .results[]? | select(.name == "commit") | .value')
        [ "$got" = "$want" ] || fails+=("fetched $got, want $want")
      fi
      d=$(jq -r '.expect.deployer // "knative"' <<<"$c")
      case $d in
        knative) kubectl get ksvc -n "$ns" "$name" >/dev/null 2>&1 || fails+=("no Knative Service $name")
                 u="http://$name.$ns.svc.cluster.local" ;;
        raw)     kubectl get deploy,svc -n "$ns" "$name" >/dev/null 2>&1 || fails+=("no Deployment and Service $name")
                 ! kubectl get ksvc -n "$ns" "$name" >/dev/null 2>&1 || fails+=("a Knative Service $name as well")
                 u="http://$name.$ns.svc.cluster.local" ;;
        keda)    kubectl get httpscaledobject -n "$ns" "$name" >/dev/null 2>&1 || fails+=("no HTTPScaledObject $name")
                 u="http://$name-interceptor-bridge.$ns.svc:8080" ;;  # a host the HTTPScaledObject registers
      esac
      image=$(kubectl get ksvc -n "$ns" "$name" -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
      [ -n "$image" ] || image=$(kubectl get deploy -n "$ns" "$name" -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
      if command -v skopeo >/dev/null; then
        label=$(skopeo inspect ${INSECURE:+--tls-verify=false} "docker://${image/:latest@/@}" 2>/dev/null \
          | jq -r '.Labels["org.opencontainers.image.revision"] // empty')
        if [ -z "$label" ]; then echo "image label: not checked (cannot read $image)" >> "$log"
        else
          echo "image label: $label" >> "$log"
          [ "$label" = "${want:0:7}" ] || fails+=("image label $label, want ${want:0:7}")
        fi
      fi
      answer=$(jq -r .expect.answer <<<"$c")
      curlpod
      body=
      for _ in $(seq 1 30); do
        body=$(get "$u" | tr -d '\r' | sed -e 's/[[:space:]]*$//')
        [ "$body" = "$answer" ] && break
        sleep 3
      done
      echo "answer from $u: $body" >> "$log"
      [ "$body" = "$answer" ] || fails+=("answered \"$(echo $body | cut -c1-80)\", want \"$answer\"")
    fi
    [ -n "$KEEP" ] || clean "$name" "$ns" "${image:-}"
    [ -z "$NODE" ] || echo "node free disk after cleanup: $(docker exec "$NODE" df -h --output=avail /var | tail -1 | tr -d ' ')" >> "$log"
  fi

  reason=$(jq -r '.known // empty' <<<"$c")
  printf 'checks: %s\n' "${fails[@]:-all passed}" >> "$log"
  if [ ${#fails[@]} -eq 0 ]; then
    if [ -n "$reason" ]; then
      printf 'PASS   %-36s %4ss  (marked known, but passes now)\n' "$id" "$secs"
    else
      printf 'PASS   %-36s %4ss\n' "$id" "$secs"
    fi
    pass=$((pass + 1))
  elif [ -n "$reason" ]; then
    printf 'KNOWN  %-36s %4ss  %s\n' "$id" "$secs" "${fails[0]}"; nknown=$((nknown + 1))
  else
    printf 'FAIL   %-36s %4ss  %s\n' "$id" "$secs" "$(printf '%s; ' "${fails[@]}" | sed 's/; $//')"; fail=$((fail + 1))
  fi
done < <(jq -c '.cases[]' "$CASES")

echo
echo "$pass passed, $fail failed, $nknown known, $skip skipped. Logs: $OUT"
[ $fail -eq 0 ]
