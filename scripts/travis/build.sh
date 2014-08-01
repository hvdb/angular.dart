#!/bin/bash

set -o errexit pipefail
. "$(dirname $0)/../env.sh"

export SAUCE_ACCESS_KEY=`echo $SAUCE_ACCESS_KEY | rev`

echo '-----------------------'
echo '-- TEST: AngularDart --'
echo '-----------------------'
echo BROWSER=$BROWSERS
$NGDART_BASE_DIR/node_modules/jasmine-node/bin/jasmine-node playback_middleware/spec/
node "node_modules/karma/bin/karma" start karma.conf \
    --reporters=junit,dots --port=8765 --runner-port=8766 \
    --browsers=$BROWSERS --single-run --no-colors 2>&1 | tee karma-output.log

echo CKCK: exit code is $?
