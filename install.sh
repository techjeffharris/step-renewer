#!/bin/bash

set -e # exit on error
#set -x # output each line executed to stdout

# define the path to the config file, defaulting to /etc/step-renewer/step-renewer.cfg
CFG="${STEP_RENEWER_PATH:-/etc/step-renewer}"/step-renewer.cfg

# If $CFG does not point to a regular file
if [ ! -f $CFG ]; then
    # if $CFG.default does not point to a regular file 
    if [ ! -f $CFG.default ]; then 
        # send error and exit 
        echo "err: {CFG}.default not found!" | tee /dev/stderr
        exit 1;
    else
        # inform the user that a copy of the default configuration has been made 
        cp $CFG.default $CFG
        echo "$CFG not found, copied from ${CFG}.default" 
    fi
fi

# echo contents of $CFG to stdout 
echo "Parsing config file $CFG..."

# parse the 'step-renewer.cfg' file
. $CFG

# get initial certificate
$STEP_RENEWER_PATH/bin/step-init-certificate.sh

# create symbolic links to service and timer files if they don't already exist
if [ ! -e /etc/systemd/system/step-renewer.service ]; then 
    ln -s $STEP_RENEWER_PATH/step-renewer.service /etc/systemd/system/step-renewer.service
fi 

if [ ! -e /etc/systemd/system/step-renewer.timer ]; then
    ln -s $STEP_RENEWER_PATH/step-renewer.timer /etc/systemd/system/step-renewer.timer
fi

# reload systemd configuration
systemctl daemon-reload 

# enable the service and timer now
systemctl enable step-renewer.service --now
systemctl enable step-renewer.timer --now 

# output status of service and timer
systemctl status step-renewer.service
systemctl status step-renewer.timer

journalctl -xef

