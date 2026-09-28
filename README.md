# func-test

Functions for testing `func` deployments from a git repository:
`func deploy --remote --source <this repo> --source-dir <dir>`, and
Pipelines-as-Code.

On `main`, each subdirectory holds one function, each set up the way a user
may have one. Every function answers `<name>:<ref> FOO=<value>`: the answer
shows which function and revision the cluster built, and `FOO` comes from the
committed func.yaml.

## Functions on `main`

| Directory | Function | Tests |
|---|---|---|
| `rev/` | `fn-rev` | the base for the revisions below: its answer names the ref it was built from |
| `raw/` | `fn-raw` | deployer `raw` from func.yaml: a Deployment and a Service, no Knative Service |
| `keda/` | `fn-keda` | deployer `keda` from func.yaml: a Deployment and an HTTPScaledObject |
| `s2i/` | `fn-s2i` | builder `s2i` from func.yaml, with no `--builder` |
| `python/` | `fn-python` | another runtime: Python, built with pack |
| `ns/` | `fn-ns` | `namespace: func-test-pinned` in func.yaml: deployed there without `-n`; another `-n` is refused |
| `deployns/` | `fn-deployns` | the namespace recorded under `deploy.namespace`, as a deploy writes it |
| `regpin/` | `fn-regpin` | registry from func.yaml, with no `--registry` (the kind test registry) |
| `legacy/` | `fn-legacy` | a func.yaml from before specVersion 0.34 (top-level `envs` and `builder`, a `git:` block), migrated in memory: answers `FOO=legacy` |
| `release-1.21/` | `fn-release-1-21` | a func.yaml as func 1.21 wrote it (was gauron99/func-repo): specVersion 0.36.0, the deployer under `deploy.deployer`, a committed registry on quay.io that `--registry` must replace |
| `srcurl/` | `fn-srcurl` | a `build.source` committed in func.yaml is ignored: the cluster builds this repository |
| `bad/` | `fn-bad` | a func.yaml that does not parse: an error before any pipeline |
| `badns/` | `fn-badns` | an invalid namespace in func.yaml: an error before any pipeline |
| `baddomain/` | `fn-baddomain` | an invalid domain in func.yaml: an error before any pipeline |
| `badexpose/` | `fn-badexpose` | an invalid expose in func.yaml: an error before any pipeline |
| `symlink/` | `fn-symlink` | `func.yaml` is a symlink to `conf/func.yaml` |
| `nofunc/` | `-` | a directory with no `func.yaml`: `--source-dir nofunc` fails |

## Revisions

Each ref below is one commit off `main` that changes only what `fn-rev`
(`--source-dir rev`) answers, so the answer shows which ref was built.

| Ref | Kind | `fn-rev` answers | Tests |
|---|---|---|---|
| `main` | default branch | `fn-rev:main` | no revision given: the default branch |
| `1.0` | tag | `fn-rev:tag-1.0` | a tag; also given as its full commit hash |
| `1.10` | tag | `fn-rev:tag-1.10` | a ref YAML reads as the number `1.1` when unquoted |
| `feature` | branch | `fn-rev:feature` | a branch, also as the URL fragment `#feature` |
| `v2.0` | annotated tag on `feature` | `fn-rev:feature` | a tag object resolves to its commit |
| `dup` | tag and branch | `fn-rev:tag-dup` / `fn-rev:branch-dup` | the tag wins over the branch of the same name; `refs/heads/dup` picks the branch |
| `q"uote` | branch | `fn-rev:quote` | a ref with a double quote, which git allows |

## Branches with one function at the root

Each has its own history, with a single function at the root of the tree.

| Branch | Function | Tests |
|---|---|---|
| `one-function-at-root` | `fn-one` | the usual layout: one function per repository, no `--source-dir` |
| `pac-pack` | `fn-pac-pack` | Pipelines-as-Code, builder pack |
| `pac-s2i` | `fn-pac-s2i` | Pipelines-as-Code, builder s2i |

PAC reads `.tekton/` from the root of the pushed commit, hence one function at
the root. `.tekton/` is not committed, as it depends on the cluster: generate
it with `func config git set --git-branch <branch>`, commit it and push. PAC
admits one Repository per repository URL in a cluster, so set up one PAC
branch at a time.

A private repository for the credentials test: `gauron99/func-test-private`.
