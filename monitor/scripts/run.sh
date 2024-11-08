#!/usr/bin/env bash

# Determines the SGX device.
# Adapted from <https://sconedocs.github.io/sgxinstall/#determine-sgx-device>
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

CAS_ADDRESS=scone-cas.cf
LAS_ADDRESS=$( hostname -I | cut -d' ' -f1 )

PROJECT_ROOT_DIR=$( dirname -- "$( readlink -f -- "$0"; )"; )/..
HOST_METRICS_DIR=$PROJECT_ROOT_DIR/artifacts/metrics/
CAS_CONFIG_ID=$(cat "$PROJECT_ROOT_DIR/artifacts/cas/cas-config-id.out")

docker run -it --rm \
    --name "scone-python-monitor-agent" \
    $MOUNT_SGXDEVICE \
    -e "SCONE_MODE=$SCONE_MODE" \
    -e "SCONE_LAS_ADDR=$LAS_ADDRESS" \
    -e "SCONE_CAS_ADDR=$CAS_ADDRESS" \
    -e "SCONE_CONFIG_ID=$CAS_CONFIG_ID/monitor_service" \
    --pid host \
    -v /proc/meminfo:/host/proc/meminfo:ro \
    -v /proc/stat:/host/proc/stat:ro \
    -v "$HOST_METRICS_DIR:/metrics" \
    scone-python-monitor \
    /venv/bin/python3 /sgx/monitor/workers/agent.py