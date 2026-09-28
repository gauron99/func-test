# fn-srcurl

func.yaml carries its own `build.source`, pointing at another repository,
a revision `nope` and a directory `nope`.

In func.yaml: `build.source: {url: .../functions-dev/func-e2e-tests, revision: nope, dir: nope}`

## Deploy

    func deploy --remote --source https://github.com/gauron99/func-test \
        --source-dir srcurl --registry <registry> -n <namespace>

## Expect

The committed `build.source` is ignored: the PipelineRun's `gitRepository` is
this repository, `contextDir` is `srcurl`, and it answers
`fn-srcurl:main FOO=committed`.
