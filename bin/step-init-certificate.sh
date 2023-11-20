#!/bin/bash

set -e # exit on error 
#set -x # output each executed line to stdout

CFG="${STEP_RENEWER_PATH:-/etc/step-renewer}"/step-renewer.cfg
. $CFG

DURATION=10
WAITTIME=7

echo "Initializing certificate and attempting auto-renewal for $HOSTNAME..."

# create initial test certificate that expires in $DURATION seconds.
LIFESPAN="$DURATION sec" $STEP_RENEWER_PATH/bin/step-get-certificate.sh

echo "Waiting $WAITTIME seconds until the test certificate is eligible for renewal..."
sleep $WAITTIME
