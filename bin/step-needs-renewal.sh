#!/bin/bash

set -e # exit on error 
#set -x # output each executed line to stdout

CFG="${STEP_RENEWER_PATH:-/etc/step-renewer}/step-renewer.cfg"
. $CFG

THRESHOLD_ARRAY=($RENEWAL_THRESHOLD)
THRESHOLD_DURATION=${THRESHOLD_ARRAY[0]}
THRESHOLD_UNIT=${THRESHOLD_ARRAY[1]}

case $THRESHOLD_UNIT in
	"hours" | "hour" )
		STEP_UNIT=h
		;;

	"minutes" | "minute" | "mins" | "min" )
		STEP_UNIT=m
		;;
esac

THRESHOLD="$THRESHOLD_DURATION$STEP_UNIT"

step certificate needs-renewal ${CERT_LOCATION} --expires-in="$THRESHOLD"
