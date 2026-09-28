# pac-pack

One function at the root of this branch, for Pipelines-as-Code. PAC reads
`.tekton/` from the root of the pushed commit. `.tekton/` is not committed: it
depends on the cluster. Generate it with `func config git set --git-branch
pac-pack ...`, commit it, and push to this branch.
