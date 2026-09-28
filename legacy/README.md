# fn-legacy

A func.yaml from before specVersion 0.34: top-level `builder` and `envs`,
and a `git:` block. func migrates it in memory when it reads it.

In func.yaml: `specVersion: 0.33.0`, top-level `envs: [FOO=legacy]`

## Deploy

    func deploy --remote --source https://github.com/gauron99/func-test \
        --source-dir legacy --registry <registry> -n <namespace>

## Expect

It answers `fn-legacy:main FOO=legacy`: `FOO` came from the old top-level
`envs`. The old `git:` block is replaced by this repository.
