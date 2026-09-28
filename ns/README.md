# fn-ns

The namespace comes from the committed func.yaml.

In func.yaml: `namespace: func-test-pinned`

## Deploy

    func deploy --remote --source https://github.com/gauron99/func-test \
        --source-dir ns --registry <registry>

## Expect

It deploys into `func-test-pinned` with no `-n`. Create that namespace
first, with the rights the pipeline needs to deploy there. With another
`-n`, func refuses: `--namespace "<ns>" conflicts with the namespace
"func-test-pinned" in the repository's func.yaml`.
