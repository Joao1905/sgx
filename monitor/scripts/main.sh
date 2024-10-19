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



# Set docker images and CAS configs, 
CROSSCOMPILER_SCONE_IMAGE=registry.scontain.com/sconecuratedimages/crosscompilers
PYTHON_SCONE_IMAGE=registry.scontain.com/sconecuratedimages/apps:python-3.7.3-alpine3.10-scone5.9.0
LAS_SCONE_IMAGE=registry.scontain.com:5050/sconecuratedimages/kubernetes:las

CAS_MRENCLAVE="be64837f9ff7dac7adf504c943a7f105a3ee33eccb2b19145a1084888d0e045a"
CAS_ADDRESS=scone-cas.cf
LAS_ADDRESS=$( hostname -I | cut -d' ' -f1 )



# Artifacts and environment variables related to filesystem
PROJECT_ROOT_DIR=$( dirname -- "$( readlink -f -- "$0"; )"; )/..
ORIGINAL_APP_DIR=$PROJECT_ROOT_DIR/artifacts/original
HOST_APP_ENCRYPTED_DIR=$PROJECT_ROOT_DIR/artifacts/encrypted
HOST_SCRIPTS_DIR=$ORIGINAL_APP_DIR/scripts
HOST_FSPF_DIR=$PROJECT_ROOT_DIR/artifacts/fspf
HOST_METRICS_DIR=$PROJECT_ROOT_DIR/artifacts/metrics/
HOST_CAS_SESSION_DIR=$PROJECT_ROOT_DIR/artifacts/cas



rm -rf $PROJECT_ROOT_DIR/artifacts
mkdir -p $ORIGINAL_APP_DIR
mkdir -p $HOST_SCRIPTS_DIR
mkdir -p $HOST_METRICS_DIR
mkdir -p $HOST_CAS_SESSION_DIR

cp -R $PROJECT_ROOT_DIR/errors $ORIGINAL_APP_DIR/errors
cp -R $PROJECT_ROOT_DIR/models $ORIGINAL_APP_DIR/models
cp -R $PROJECT_ROOT_DIR/services $ORIGINAL_APP_DIR/services
cp -R $PROJECT_ROOT_DIR/utils $ORIGINAL_APP_DIR/utils
cp -R $PROJECT_ROOT_DIR/workers $ORIGINAL_APP_DIR/workers
cp -R $PROJECT_ROOT_DIR/certificate $ORIGINAL_APP_DIR/certificate
cp $PROJECT_ROOT_DIR/requirements.txt $ORIGINAL_APP_DIR

cp $PROJECT_ROOT_DIR/scripts/encrypt.sh $HOST_SCRIPTS_DIR/encrypt.sh
cp $PROJECT_ROOT_DIR/scripts/cas-session.sh $HOST_SCRIPTS_DIR/cas-session.sh
cp $PROJECT_ROOT_DIR/scripts/cas-cert.conf $HOST_SCRIPTS_DIR/cas-cert.conf
cp $PROJECT_ROOT_DIR/scripts/cas-template.yml $HOST_SCRIPTS_DIR/cas-template.yml

# Generate fspf table to configure filesystem and code encryption with SCONE shields
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



# Create symmetric encryption key for the metrics file
METRICS_FILE_ENCRYPTION_KEY=$(python3 -c 'from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())')



# CAS session generation
openssl req -newkey rsa:4096 -days 365 -nodes -x509 \
    -out "$HOST_CAS_SESSION_DIR/cas-cert.pem" \
    -keyout "$HOST_CAS_SESSION_DIR/cas-key.pem" \
    -config "$HOST_SCRIPTS_DIR/cas-cert.conf"

docker run -it --rm \
    $MOUNT_SGXDEVICE -e "SCONE_MODE=$SCONE_MODE" \
    --env-file $PROJECT_ROOT_DIR/.env \
    -e "METRICS_FILE_ENCRYPTION_KEY=$METRICS_FILE_ENCRYPTION_KEY" \
    -e "FSPF_KEY=$SCONE_FSPF_KEY" \
    -e "FSPF_TAG=$SCONE_FSPF_TAG" \
    -e "CAS_ADDR=$CAS_ADDRESS" \
    -e "CAS_MRENCLAVE=$CAS_MRENCLAVE" \
    -v "$HOST_CAS_SESSION_DIR:/cas" \
    -v "$HOST_SCRIPTS_DIR:/scripts" \
    $PYTHON_SCONE_IMAGE \
    "/scripts/cas-session.sh"

CAS_CONFIG_ID=$(cat "$HOST_CAS_SESSION_DIR/cas-config-id.out")



# Run LAS if not running
#[ ! "$(docker ps -a | grep scone-las)" ] && docker run -it --rm \
#    --name scone-las \
#    $MOUNT_SGXDEVICE \
#    -e "SCONE_MODE=$SCONE_MODE" \
#    -p 18766:18766 \
#    --network host \
#    --detach \
#    $LAS_SCONE_IMAGE > /dev/null



# Build and run monitor agent
docker build "$PROJECT_ROOT_DIR" \
    -t "scone-python-monitor"

docker run -it --rm \
    --name "scone-python-monitor-agent" \
    $MOUNT_SGXDEVICE \
    -e "SCONE_MODE=$SCONE_MODE" \
    -e "SCONE_LAS_ADDR=$LAS_ADDRESS" \
    -e "SCONE_CAS_ADDR=$CAS_ADDRESS" \
    -e "SCONE_CONFIG_ID=$CAS_CONFIG_ID/monitor_service" \
    --pid host \
    -v /proc/meminfo:/host/proc/meminfo:ro \
    -v "$HOST_METRICS_DIR:/metrics" \
    scone-python-monitor \
    python3 /sgx/monitor/workers/agent.py


# Run without CAS and LAS
#docker run -it --rm \
#    $MOUNT_SGXDEVICE -e "SCONE_MODE=$SCONE_MODE" \
#    --env-file $PROJECT_ROOT_DIR/.env \
#    -e "SCONE_FSPF_KEY=$SCONE_FSPF_KEY" \
#    -e "SCONE_FSPF_TAG=$SCONE_FSPF_TAG" \
#    -e "SCONE_FSPF=/fspf/fspf.pb" \
#    -e "METRICS_FILE_ENCRYPTION_KEY=$METRICS_FILE_ENCRYPTION_KEY" \
#    --pid host \
#    -v /proc/meminfo:/host/proc/meminfo:ro \
#    -v "$HOST_METRICS_DIR:/metrics" \
#    --detach \
#    scone-python-monitor \
#    python3 /sgx/monitor/workers/agent.py
#
#
#docker run -it --rm \
#    $MOUNT_SGXDEVICE -e "SCONE_MODE=$SCONE_MODE" \
#    --env-file $PROJECT_ROOT_DIR/.env \
#    -e "SCONE_FSPF_KEY=$SCONE_FSPF_KEY" \
#    -e "SCONE_FSPF_TAG=$SCONE_FSPF_TAG" \
#    -e "SCONE_FSPF=/fspf/fspf.pb" \
#    -e "METRICS_FILE_ENCRYPTION_KEY=$METRICS_FILE_ENCRYPTION_KEY" \
#    -v "$HOST_METRICS_DIR:/metrics" \
#    -p 8000:5000 \
#    scone-python-monitor \
#    python3 /sgx/monitor/workers/api.py