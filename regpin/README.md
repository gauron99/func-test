# fn-regpin

The registry comes from the committed func.yaml, with no `--registry`.

In func.yaml: `registry: registry.localtest.me/pinned`

## Deploy

    func deploy --remote --source https://github.com/gauron99/func-test \
        --source-dir regpin --registry-insecure -n <namespace>

## Expect

The image is `registry.localtest.me/pinned/fn-regpin`. That is the plain-HTTP
registry of the kind cluster func sets up for testing, hence
`--registry-insecure`; elsewhere the push fails. A `--registry` flag would
replace it.
