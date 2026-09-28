# pac-s2i

One function, `fn-pac-s2i` (builder s2i), at the root of this branch, for
Pipelines-as-Code. PAC reads `.tekton/` from the root of the pushed commit.

`.tekton/` is committed, made with:

    func create --path /tmp/pac-func/fn-pac-s2i -l go
    func config git set --git-provider github \
        --git-url https://github.com/gauron99/func-test --git-branch pac-s2i --git-dir . \
        --builder s2i --registry registry.localtest.me/func-test --namespace func-test \
        --config-local --config-cluster=false --config-remote=false

So it builds for the kind cluster func sets up for testing: it pushes to
`registry.localtest.me/func-test`. The PipelineRun runs on pushes to `pac-s2i`.
For another cluster, run `func config git set` again and commit the result.
Setting up PAC on the cluster and the webhook is `func config git set
--config-cluster --config-remote`.

`fn-pac-s2i` answers `fn-pac-s2i:pac-s2i FOO=committed`. Deployed by reference
(`func deploy --remote --source <repo> --revision pac-s2i`), the committed
`.tekton/` plays no part.

Note: `--git-dir .` stands for the root. With `--git-dir ""`, func still asks
for the directory, which fails without a terminal.
