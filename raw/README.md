# fn-raw

The deployer is chosen in the committed func.yaml, not with `--deployer`.

In func.yaml: `deployer: raw`

## Deploy

    func deploy --remote --source https://github.com/gauron99/func-test \
        --source-dir raw --registry <registry> -n <namespace>

## Expect

A Deployment and a Service named `fn-raw`, no Knative Service. The URL is
in-cluster only: `http://fn-raw.<namespace>.svc`. It answers
`fn-raw:main FOO=committed`.
