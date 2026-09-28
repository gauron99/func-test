# fn-bad

A func.yaml that does not parse.

In func.yaml: `run.envs: not-a-list`

## Deploy

    func deploy --remote --source https://github.com/gauron99/func-test \
        --source-dir bad --registry <registry> -n <namespace>

## Expect

An error before any pipeline runs:
``'func.yaml' is not valid: ... cannot unmarshal !!str `not-a-list` into functions.Envs``.
