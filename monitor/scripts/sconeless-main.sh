#!/usr/bin/env bash

# Set docker images and CAS configs, 
PYTHON_DEFAULT_IMAGE=python:3.7.3

# Artifacts and environment variables related to filesystem
PROJECT_ROOT_DIR=$( dirname -- "$( readlink -f -- "$0"; )"; )/..
ORIGINAL_APP_DIR=$PROJECT_ROOT_DIR/artifacts/original
HOST_SCRIPTS_DIR=$ORIGINAL_APP_DIR/scripts
HOST_METRICS_DIR=$PROJECT_ROOT_DIR/artifacts/metrics/


rm -rf $PROJECT_ROOT_DIR/artifacts
mkdir -p $ORIGINAL_APP_DIR
mkdir -p $HOST_SCRIPTS_DIR
mkdir -p $HOST_METRICS_DIR

cp -R $PROJECT_ROOT_DIR/errors $ORIGINAL_APP_DIR/errors
cp -R $PROJECT_ROOT_DIR/models $ORIGINAL_APP_DIR/models
cp -R $PROJECT_ROOT_DIR/services $ORIGINAL_APP_DIR/services
cp -R $PROJECT_ROOT_DIR/utils $ORIGINAL_APP_DIR/utils
cp -R $PROJECT_ROOT_DIR/workers $ORIGINAL_APP_DIR/workers
cp -R $PROJECT_ROOT_DIR/certificate $ORIGINAL_APP_DIR/certificate
cp $PROJECT_ROOT_DIR/requirements.txt $ORIGINAL_APP_DIR


# Create symmetric encryption key for the metrics file
METRICS_FILE_ENCRYPTION_KEY=$(python3 -c 'import base64; import libnacl.utils; key = libnacl.utils.salsa_key(); print(base64.b64encode(key).decode())')
METRICS_FILE_ENCRYPTION_NONCE=$(python3 -c 'import libnacl.utils; import base64; nonce = libnacl.utils.rand_nonce(); print(base64.b64encode(nonce).decode())')


# Build and run monitor agent
docker build "$PROJECT_ROOT_DIR" \
    -f "$PROJECT_ROOT_DIR/sconeless-dockerfile" \
    -t "sconeless-python-monitor"


# Run
docker run -it -d --rm \
    --env-file $PROJECT_ROOT_DIR/.env \
    -e "METRICS_FILE_ENCRYPTION_KEY=$METRICS_FILE_ENCRYPTION_KEY" \
    -e "METRICS_FILE_ENCRYPTION_NONCE=$METRICS_FILE_ENCRYPTION_NONCE" \
    -v /proc/meminfo:/host/proc/meminfo:ro \
    -v /proc/stat:/host/proc/stat:ro \
    -v "$HOST_METRICS_DIR:/metrics" \
    sconeless-python-monitor \
    python3 /sgx/monitor/workers/agent.py


docker run -it --rm \
    --env-file $PROJECT_ROOT_DIR/.env \
    -e "METRICS_FILE_ENCRYPTION_KEY=$METRICS_FILE_ENCRYPTION_KEY" \
    -e "METRICS_FILE_ENCRYPTION_NONCE=$METRICS_FILE_ENCRYPTION_NONCE" \
    -v "$HOST_METRICS_DIR:/metrics" \
    -p 8000:5000 \
    sconeless-python-monitor \
    python3 /sgx/monitor/workers/api.py