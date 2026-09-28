# fn-release-1-21

A func.yaml as func 1.21 wrote it (this was gauron99/func-repo):
specVersion 0.36.0, the 1.21 schema, the deployer under `deploy.deployer`, and a
committed registry on quay.io.

In func.yaml: `specVersion: 0.36.0`, `deploy.deployer: raw`, `registry: quay.io/dfridric`

## Deploy

    func deploy --remote --source https://github.com/gauron99/func-test \
        --source-dir release-1.21 --registry <registry> -n <namespace>

## Expect

A Deployment named `fn-release-1-21`, no Knative Service: `deploy.deployer`
still chooses the deployer. The image goes to `<registry>`: the flag replaces
the committed quay.io registry. Without `--registry` the cluster would push to
quay.io and fail for lack of credentials. It answers
`fn-release-1-21:main FOO=committed`.
