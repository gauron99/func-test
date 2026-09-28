# nofunc

A directory with no func.yaml.

## Deploy

    func deploy --remote --source https://github.com/gauron99/func-test \
        --source-dir nofunc --registry <registry> -n <namespace>

## Expect

An error before any pipeline runs: `no func.yaml in "nofunc" of <repository> at <revision>`.
