# fn-s2i

The builder is chosen in the committed func.yaml, with no `--builder`.

In func.yaml: `build.builder: s2i`

## Deploy

    func deploy --remote --source https://github.com/gauron99/func-test \
        --source-dir s2i --registry <registry> -n <namespace>

## Expect

The PipelineRun is named `func-<hash>-s2i-git-run-...` and runs the s2i
steps (`generate`, then `build` with buildah). It answers
`fn-s2i:main FOO=committed`. An s2i build of Go in the cluster needs several
GB of free disk on the node.
