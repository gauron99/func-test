# fn-badns

An invalid namespace in func.yaml.

In func.yaml: `namespace: Not_A_Namespace`

## Deploy

    func deploy --remote --source https://github.com/gauron99/func-test \
        --source-dir badns --registry <registry>

## Expect

An error before any pipeline runs: `invalid namespace`. (With `-n`, func
reports the conflict with the committed namespace first.)
