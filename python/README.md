# fn-python

A second runtime: Python, built with pack.

In func.yaml: `runtime: python`

## Deploy

    func deploy --remote --source https://github.com/gauron99/func-test \
        --source-dir python --registry <registry> -n <namespace>

## Expect

It answers `fn-python:main FOO=committed`. The Python builder image is
large (about 5 GB unpacked).
