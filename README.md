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
