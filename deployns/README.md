# fn-deployns

The namespace is recorded under `deploy.namespace`, where a deploy writes
it, instead of the top-level `namespace`.

In func.yaml: `deploy.namespace: func-test-pinned`

## Deploy

    func deploy --remote --source https://github.com/gauron99/func-test \
        --source-dir deployns --registry <registry>

## Expect

The same as `ns/`: it deploys into `func-test-pinned` with no `-n`, and
another `-n` is refused.
