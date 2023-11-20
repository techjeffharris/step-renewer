#!/bin/bash

set -e
#set -x

# load the configuration.
CFG="${STEP_RENEWER_PATH:-/etc/step-renewer}"/step-renewer.cfg
. $CFG

if [ ! -z "$LIFESPAN" ]; then
	# When LIFESPAN is set, expiration will be relative to now
	EXPIRATION=$(date -d "$(date) + $LIFESPAN")
else
	# When LIFESPAN is not set, expiration will be relative to today at 00:00:00
	EXPIRATION=$(date -d "$(date -Idate -d "$RENEWAL_FREQUENCY") $EXPIRATION_TIME")
fi

# Expiration is the date "now" + OFFSET in ISO 8601 format
EXPIRATION_ISO8601=$(date -Iseconds -d "$EXPIRATION")

echo $EXPIRATION_ISO8601
