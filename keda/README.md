# fn-keda

The deployer is chosen in the committed func.yaml, not with `--deployer`.

In func.yaml: `deployer: keda`

## Deploy

    func deploy --remote --source https://github.com/gauron99/func-test \
        --source-dir keda --registry <registry> -n <namespace>

## Expect

A Deployment and an HTTPScaledObject named `fn-keda`. Needs KEDA and its
HTTP add-on in the cluster. The URL is in-cluster only:
`http://fn-keda-interceptor-bridge.<namespace>.svc:8080`. It answers
`fn-keda:main FOO=committed`.
