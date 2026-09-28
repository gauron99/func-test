# fn-baddomain

An invalid domain in func.yaml.

In func.yaml: `domain: not_a_domain`

## Deploy

    func deploy --remote --source https://github.com/gauron99/func-test \
        --source-dir baddomain --registry <registry> -n <namespace>

## Expect

An error before any pipeline runs: `invalid domain`.
