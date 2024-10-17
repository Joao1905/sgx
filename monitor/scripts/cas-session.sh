#!/usr/bin/env bash

# Install dependencies.
apk add gettext curl

# Paths to useful directories.
SCRIPT_DIR=/scripts
CAS_DIR=/cas
cd "$SCRIPT_DIR"

# Generate the session ID.
export SCONE_CONFIG_ID="monitor-$RANDOM-$RANDOM-$RANDOM"
echo $SCONE_CONFIG_ID > "$CAS_DIR/cas-config-id.out"

# Generate the MRENCLAVE of the Python executable.
unset MRENCLAVE
export MRENCLAVE=$(SCONE_HASH=1 python3)

# Load variable defaults.
[ -z "${AGENT_ID}" ] && AGENT_ID=0
[ -z "${MONITOR_DELAY_SECS}" ] && MONITOR_DELAY_SECS=10
[ -z "${METRICS_PATH}" ] && METRICS_PATH=/metrics/metrics.txt
[ -z "${X_API_KEY}" ] && X_API_KEY=defaultkey
[ -z "${METRICS_FILE_ENCRYPTION_KEY}" ] && METRICS_FILE_ENCRYPTION_KEY="mFb1lxJhgx087cXOTJHlO9D-EJ60gFBjQwTAVADxGY4="

# Generate the session file.
envsubst < "$SCRIPT_DIR/cas-template.yml" > "$CAS_DIR/cas-session.yml"

# Send the session creation request to the CAS.
curl -v -k -s \
    --cert "$CAS_DIR/cas-cert.pem" \
    --key "$CAS_DIR/cas-key.pem" \
    --data-binary "@$CAS_DIR/cas-session.yml" \
    -X POST https://$CAS_ADDR:8081/session