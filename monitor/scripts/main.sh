#!/usr/bin/env bash

# mrenclave1 = adfcffbdf0d36f7fc8888527d754df4036db38f6b48789968792ca453526bbce
# mrenclave2 = 4df208ca0e2980cd819f6e9e891e0a61e52eb2aa3e6e72fb0b30f663f2fccded

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
PYTHON_DEFAULT_IMAGE=python:3.7.3
PYTHON_SCONE_IMAGE=registry.scontain.com/sconecuratedimages/apps:python-3.7.3-alpine3.10-scone5.9.0
LAS_SCONE_IMAGE=registry.scontain.com/sconecuratedimages/las:scone5.9.0

CAS_MRENCLAVE="be64837f9ff7dac7adf504c943a7f105a3ee33eccb2b19145a1084888d0e045a"
CAS_ADDRESS=scone-cas.cf
LAS_ADDRESS=$( hostname -I | cut -d' ' -f1 )



# Artifacts and environment variables related to filesystem
PROJECT_ROOT_DIR=$( dirname -- "$( readlink -f -- "$0"; )"; )/..
ORIGINAL_APP_DIR=$PROJECT_ROOT_DIR/artifacts/original
HOST_APP_ENCRYPTED_DIR=$PROJECT_ROOT_DIR/artifacts/encrypted
HOST_SCRIPTS_DIR=$ORIGINAL_APP_DIR/scripts
HOST_VENV_DIR=$PROJECT_ROOT_DIR/artifacts/venv
HOST_FSPF_DIR=$PROJECT_ROOT_DIR/artifacts/fspf
HOST_METRICS_DIR=$PROJECT_ROOT_DIR/artifacts/metrics/
HOST_CAS_SESSION_DIR=$PROJECT_ROOT_DIR/artifacts/cas


rm -rf $PROJECT_ROOT_DIR/artifacts
mkdir -p $ORIGINAL_APP_DIR
mkdir -p $HOST_SCRIPTS_DIR
mkdir -p $HOST_VENV_DIR
mkdir -p $HOST_METRICS_DIR
mkdir -p $HOST_CAS_SESSION_DIR

cp -R $PROJECT_ROOT_DIR/errors $ORIGINAL_APP_DIR/errors
cp -R $PROJECT_ROOT_DIR/models $ORIGINAL_APP_DIR/models
cp -R $PROJECT_ROOT_DIR/services $ORIGINAL_APP_DIR/services
cp -R $PROJECT_ROOT_DIR/utils $ORIGINAL_APP_DIR/utils
cp -R $PROJECT_ROOT_DIR/workers $ORIGINAL_APP_DIR/workers
cp -R $PROJECT_ROOT_DIR/certificate $ORIGINAL_APP_DIR/certificate
cp $PROJECT_ROOT_DIR/requirements.txt $ORIGINAL_APP_DIR

cp $PROJECT_ROOT_DIR/scripts/venv.sh $HOST_SCRIPTS_DIR/venv.sh
cp $PROJECT_ROOT_DIR/scripts/sconify.sh $HOST_SCRIPTS_DIR/sconify.sh
cp $PROJECT_ROOT_DIR/scripts/encrypt.sh $HOST_SCRIPTS_DIR/encrypt.sh
cp $PROJECT_ROOT_DIR/scripts/cas-session.sh $HOST_SCRIPTS_DIR/cas-session.sh
cp $PROJECT_ROOT_DIR/scripts/cas-cert.conf $HOST_SCRIPTS_DIR/cas-cert.conf
cp $PROJECT_ROOT_DIR/scripts/cas-template.yml $HOST_SCRIPTS_DIR/cas-template.yml



# Generate and sconify venv
docker run -it --rm \
    $MOUNT_SGXDEVICE -e "SCONE_MODE=$SCONE_MODE" \
    -v "$HOST_VENV_DIR/:/venv" \
    -v "$ORIGINAL_APP_DIR:/original" \
    "$PYTHON_DEFAULT_IMAGE" \
    "/original/scripts/venv.sh"

docker run -it --rm \
    $MOUNT_SGXDEVICE -e "SCONE_MODE=$SCONE_MODE" \
    -v "SCONE_FORK=1" \
    -v "$HOST_VENV_DIR/:/venv" \
    -v "$ORIGINAL_APP_DIR:/original" \
    "$PYTHON_SCONE_IMAGE" \
    "/original/scripts/sconify.sh"



# Generate fspf table to configure filesystem and code encryption with SCONE shields
docker run -it --rm \
    $MOUNT_SGXDEVICE -e "SCONE_MODE=$SCONE_MODE" \
    -v "$ORIGINAL_APP_DIR:/original" \
    -v "$HOST_APP_ENCRYPTED_DIR:/sgx/monitor" \
    -v "$HOST_METRICS_DIR:/metrics" \
    -v "$HOST_FSPF_DIR:/fspf" \
    -v "$HOST_VENV_DIR:/unauth_venv" \
    "$CROSSCOMPILER_SCONE_IMAGE" \
    "/original/scripts/encrypt.sh"

export SCONE_FSPF_KEY=$(cat "$HOST_FSPF_DIR/keytag.out" | awk '{print $11}')
export SCONE_FSPF_TAG=$(cat "$HOST_FSPF_DIR/keytag.out" | awk '{print $9}')



# Create symmetric encryption key for the metrics file
## Maybe use seal and unseal from native SGX
METRICS_FILE_ENCRYPTION_KEY=$(python3 -c 'import base64; import libnacl.utils; key = libnacl.utils.salsa_key(); print(base64.b64encode(key).decode())')
METRICS_FILE_ENCRYPTION_NONCE=$(python3 -c 'import libnacl.utils; import base64; nonce = libnacl.utils.rand_nonce(); print(base64.b64encode(nonce).decode())')



# CAS session generation
openssl req -newkey rsa:4096 -days 365 -nodes -x509 \
    -out "$HOST_CAS_SESSION_DIR/cas-cert.pem" \
    -keyout "$HOST_CAS_SESSION_DIR/cas-key.pem" \
    -config "$HOST_SCRIPTS_DIR/cas-cert.conf" \
    -extensions v3_req

docker run -it --rm \
    $MOUNT_SGXDEVICE -e "SCONE_MODE=$SCONE_MODE" \
    --env-file $PROJECT_ROOT_DIR/.env \
    -e "METRICS_FILE_ENCRYPTION_KEY=$METRICS_FILE_ENCRYPTION_KEY" \
    -e "METRICS_FILE_ENCRYPTION_NONCE=$METRICS_FILE_ENCRYPTION_NONCE" \
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
[ ! "$(docker ps -a | grep scone-las)" ] && docker run -it --rm \
    --name scone-las \
    $MOUNT_SGXDEVICE \
    -e "SCONE_MODE=$SCONE_MODE" \
    -v "/var:/var" \
    -p 18766:18766 \
    --network host \
    --detach \
    $LAS_SCONE_IMAGE > /dev/null



# Build and run monitor agent
docker build "$PROJECT_ROOT_DIR" \
    -t "scone-python-monitor"


# Run without CAS and LAS
#docker run -it --rm \
#    $MOUNT_SGXDEVICE -e "SCONE_MODE=$SCONE_MODE" \
#    --env-file $PROJECT_ROOT_DIR/.env \
#    -e "SCONE_FSPF_KEY=$SCONE_FSPF_KEY" \
#    -e "SCONE_FSPF_TAG=$SCONE_FSPF_TAG" \
#    -e "SCONE_FSPF=/fspf/fspf.pb" \
#    -e "METRICS_FILE_ENCRYPTION_KEY=$METRICS_FILE_ENCRYPTION_KEY" \
#    -e "METRICS_FILE_ENCRYPTION_NONCE=$METRICS_FILE_ENCRYPTION_NONCE" \
#    -v /proc/meminfo:/host/proc/meminfo:ro \
#    -v /proc/stat:/host/proc/stat:ro \
#    -v "$HOST_METRICS_DIR:/metrics" \
#    scone-python-monitor \
#    /venv/bin/python3 /sgx/monitor/workers/agent.py
#
#
#docker run -it --rm \
#    $MOUNT_SGXDEVICE -e "SCONE_MODE=$SCONE_MODE" \
#    --env-file $PROJECT_ROOT_DIR/.env \
#    -e "SCONE_FSPF_KEY=$SCONE_FSPF_KEY" \
#    -e "SCONE_FSPF_TAG=$SCONE_FSPF_TAG" \
#    -e "SCONE_FSPF=/fspf/fspf.pb" \
#    -e "METRICS_FILE_ENCRYPTION_KEY=$METRICS_FILE_ENCRYPTION_KEY" \
#    -e "METRICS_FILE_ENCRYPTION_NONCE=$METRICS_FILE_ENCRYPTION_NONCE" \
#    -v "$HOST_METRICS_DIR:/metrics" \
#    -p 8000:5000 \
#    scone-python-monitor \
#    /venv/bin/python3 /sgx/monitor/workers/api.py