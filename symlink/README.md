# fn-symlink

`func.yaml` is a symlink to `conf/func.yaml`, which works for a local
function.

The link: `func.yaml -> conf/func.yaml`

## Deploy

    func deploy --remote --source https://github.com/gauron99/func-test \
        --source-dir symlink --registry <registry> -n <namespace>

## Expect

func reads `conf/func.yaml` through the link and deploys `fn-symlink`, as it
does for a local function. If func instead reports
`` 'func.yaml' is not valid: ... cannot unmarshal !!str `conf/fu...` ``, it read
the text of the link itself.
