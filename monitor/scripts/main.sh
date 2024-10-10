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

CROSSCOMPILER_SCONE_IMAGE=registry.scontain.com/sconecuratedimages/crosscompilers
PYTHON_SCONE_IMAGE=registry.scontain.com/sconecuratedimages/apps:python-3.7.3-alpine3.10-scone5.9.0

PROJECT_ROOT_DIR=$( dirname -- "$( readlink -f -- "$0"; )"; )/..
ORIGINAL_APP_DIR=$PROJECT_ROOT_DIR/artifacts/original
HOST_APP_ENCRYPTED_DIR=$PROJECT_ROOT_DIR/artifacts/encrypted
HOST_FSPF_DIR=$PROJECT_ROOT_DIR/artifacts/fspf
HOST_METRICS_DIR=$PROJECT_ROOT_DIR/artifacts/metrics/

rm -rf $PROJECT_ROOT_DIR/artifacts
mkdir -p $ORIGINAL_APP_DIR
mkdir -p $ORIGINAL_APP_DIR/scripts/

mkdir -p $HOST_METRICS_DIR
touch $HOST_METRICS_DIR/metrics.txt

cp -R $PROJECT_ROOT_DIR/errors $ORIGINAL_APP_DIR/errors
cp -R $PROJECT_ROOT_DIR/models $ORIGINAL_APP_DIR/models
cp -R $PROJECT_ROOT_DIR/services $ORIGINAL_APP_DIR/services
cp -R $PROJECT_ROOT_DIR/utils $ORIGINAL_APP_DIR/utils
cp -R $PROJECT_ROOT_DIR/workers $ORIGINAL_APP_DIR/workers
cp $PROJECT_ROOT_DIR/scripts/encrypt.sh $ORIGINAL_APP_DIR/scripts/encrypt.sh
cp $PROJECT_ROOT_DIR/requirements.txt $ORIGINAL_APP_DIR

docker run -it --rm \
    $MOUNT_SGXDEVICE -e "SCONE_MODE=$SCONE_MODE" \
    -v "$ORIGINAL_APP_DIR:/original" \
    -v "$HOST_APP_ENCRYPTED_DIR:/sgx/monitor" \
    -v "$HOST_METRICS_DIR:/metrics" \
    -v "$HOST_FSPF_DIR:/fspf" \
    "$CROSSCOMPILER_SCONE_IMAGE" \
    "/original/scripts/encrypt.sh"

export SCONE_FSPF_KEY=$(cat "$HOST_FSPF_DIR/keytag.out" | awk '{print $11}')
export SCONE_FSPF_TAG=$(cat "$HOST_FSPF_DIR/keytag.out" | awk '{print $9}')

docker build "$PROJECT_ROOT_DIR" \
    -t "scone-python-monitor"

docker run -it --rm \
    $MOUNT_SGXDEVICE -e "SCONE_MODE=$SCONE_MODE" \
    --env-file $PROJECT_ROOT_DIR/.env \
    -e "SCONE_FSPF_KEY=$SCONE_FSPF_KEY" \
    -e "SCONE_FSPF_TAG=$SCONE_FSPF_TAG" \
    -e "SCONE_FSPF=/fspf/fspf.pb" \
    --pid host \
    -v /proc/meminfo:/host/proc/meminfo:ro \
    -v "$HOST_METRICS_DIR:/metrics" \
    --detach \
    scone-python-monitor \
    sh -c "python3 /sgx/monitor/workers/agent.py"




docker build "$PROJECT_ROOT_DIR" \
    -f ../dockerfile-api \
    -t "scone-python-monitor-api"

docker run -it --rm \
    $MOUNT_SGXDEVICE -e "SCONE_MODE=$SCONE_MODE" \
    --env-file $PROJECT_ROOT_DIR/.env \
    -v "$HOST_METRICS_DIR:/metrics" \
    -p 8000:5000 \
    scone-python-monitor-api \
    sh -c "python3 -m flask --app /sgx/monitor/workers/api.py run --host=0.0.0.0"