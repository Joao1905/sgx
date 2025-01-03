#!/usr/bin/env bash

SCRIPT_FOLDER=$( dirname -- "$( readlink -f -- "$0"; )"; )

export SGXDEVICE="/dev/sgx/enclave"
export MOUNT_SGXDEVICE="--device=/dev/sgx/enclave --device=/dev/sgx/provision"
export SCONE_MODE="hw"
if [[ ! -e "$SGXDEVICE" ]] ; then
    export SGXDEVICE="/dev/sgx"
    export MOUNT_SGXDEVICE="--device=/dev/sgx"
    if [[ ! -e "$SGXDEVICE" ]] ; then
        export SGXDEVICE="/dev/isgx"
        export MOUNT_SGXDEVICE="--device=/dev/isgx"
        if [[ ! -c "$SGXDEVICE" ]] ; then
            echo "Warning: No SGX device found! Will run in SIM mode." > /dev/stderr
            export MOUNT_SGXDEVICE=""
            export SGXDEVICE=""
            export SCONE_MODE="sim"
        fi
    fi
fi

[ ! "$(docker ps -a | grep scone-las)" ] && docker run --rm \
    --name scone-las \
    $MOUNT_SGXDEVICE \
    -e "SCONE_MODE=$SCONE_MODE" \
    -v "/var/run/aesmd:/var/run/aesmd" \
    -p 18766:18766 \
    --privileged \
    "registry.scontain.com/sconecuratedimages/las:scone5.9.0" > /dev/null