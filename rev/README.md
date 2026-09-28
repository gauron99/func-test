# fn-rev

The function the revisions change. `main` and every ref listed in the
top-level README hold the same function; only its answer differs, so the answer
shows which ref the cluster built.

In func.yaml: nothing special.

## Deploy

    func deploy --remote --source https://github.com/gauron99/func-test \
        --source-dir rev --registry <registry> -n <namespace> \
        --revision 1.10

## Expect

It answers `fn-rev:<ref> FOO=committed`, for example `fn-rev:tag-1.10` for
`--revision 1.10`, and `fn-rev:main` with no `--revision`. The PipelineRun's
`gitRevision` is the full hash of the commit the ref points to.
