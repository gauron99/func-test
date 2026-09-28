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
