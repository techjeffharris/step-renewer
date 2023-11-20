#!/bin/bash

# Load step-renewr.cfg
CFG=${STEP_RENEWER_PATH:-/etc/step-renewer}/step-renewer.cfg
. $CFG

echo "step-renewer successfully updated the certificate!"

echo "Warning: This is the default EXEC_START_POST script."
echo "Warning: You ought to update the 'EXEC_START_POST' variable in your step-renewer.cfg to point to a custom script, optionally a modified copy of this one."
