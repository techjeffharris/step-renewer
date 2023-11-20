#!/bin/bash

set -e # exit on error 
#set -x # output each executed line to stdout

# load the config file
CFG=${STEP_RENEWER_PATH:-/etc/step-renewer}/step-renewer.cfg
. $CFG

LISTEN=
SANS=

# When $LIFESPAN is a zero-length string
if [ -z "$LIFESPAN" ]; then
        # If LIFESPAN is not set, get the expiration date from step-expiration.sh
        NOT_AFTER=$(${STEP_RENEWER_PATH}/bin/step-expiration.sh)
else
        # If LIFESPAN is set, pass it to step-expiration.sh
        NOT_AFTER="$(LIFESPAN="$LIFESPAN" ${STEP_RENEWER_PATH}/bin/step-expiration.sh)"
fi

# When $WEBROOT is not a zero-length string
if [ ! -z "$WEBROOT" ]
then
        # If webroot is set, configure the appropriate argument
        STEP_WEBROOT="--webroot $WEBROOT"
fi

# When $ACME_LISTEN_ADDRESS is not a zero-length string
if [ ! -z "$ACME_LISTEN_ADDRESS" ]
then
	LISTEN="--standalone --http-listen $ACME_LISTEN_ADDRESS"	
fi

# Build string of Subject Alternate Names AKA SANs
for SUBJECT_ALT_NAME in "${SUBJECT_ALT_NAMES[@]}"
do
	# When $SANS is empty (haha)
	if [ -z "$SANS" ]
	then
		SANS="--san $SUBJECT_ALT_NAME"
	else
		SANS="$SANS --san $SUBJECT_ALT_NAME"
	fi

done

# Create the new certificate
step ca certificate $HOSTNAME $CERT_LOCATION $KEY_LOCATION $SANS --provisioner acme --kty $KTY --not-after $NOT_AFTER --force $STEP_WEBROOT $LISTEN

# Inspect the created certificate
step certificate inspect $CERT_LOCATION --short

# Update certificate chain file
cat $CERT_LOCATION $CA_CERT > $CERT_CHAIN
