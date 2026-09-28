# fn-badexpose

An invalid expose value in func.yaml.

In func.yaml: `expose: nope`

## Deploy

    func deploy --remote --source https://github.com/gauron99/func-test \
        --source-dir badexpose --registry <registry> -n <namespace>

## Expect

An error before any pipeline runs: `'func.yaml' contains errors: invalid
expose value: "nope"`.
