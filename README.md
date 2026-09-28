# pac-pack

One function, `fn-pac-pack` (builder pack), at the root of this branch, for
Pipelines-as-Code. PAC reads `.tekton/` from the root of the pushed commit.

`.tekton/` is committed, made with:

    func create --path /tmp/pac-func/fn-pac-pack -l go
    func config git set --git-provider github \
        --git-url https://github.com/gauron99/func-test --git-branch pac-pack --git-dir . \
        --builder pack --registry registry.localtest.me/func-test --namespace func-test \
        --config-local --config-cluster=false --config-remote=false

So it builds for the kind cluster func sets up for testing: it pushes to
`registry.localtest.me/func-test`. The PipelineRun runs on pushes to `pac-pack`.
For another cluster, run `func config git set` again and commit the result.
Setting up PAC on the cluster and the webhook is `func config git set
--config-cluster --config-remote`.

`fn-pac-pack` answers `fn-pac-pack:pac-pack FOO=committed`. Deployed by reference
(`func deploy --remote --source <repo> --revision pac-pack`), the committed
`.tekton/` plays no part.

Note: `--git-dir .` stands for the root. With `--git-dir ""`, func still asks
for the directory, which fails without a terminal.
