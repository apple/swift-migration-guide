set -euxo pipefail

export DOCC_JSON_PRETTYPRINT="YES"

output="./migration-guide"

xcrun docc convert --experimental-enable-custom-templates --output-path ./migration-guide Guide.docc

pushd migration-guide

ruby -run -e httpd -- . -p 8000
