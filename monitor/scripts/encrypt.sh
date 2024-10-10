#!/usr/bin/env bash

ORIGINAL_DIR=/original
ENCRYPTED_DIR=/sgx/monitor
FSPF_DIR=/fspf
METRICS_DIR=/metrics

mkdir -p $ENCRYPTED_DIR
mkdir -p $FSPF_DIR

mkdir -p /metrics_temp
cp $METRICS_DIR/metrics.txt /metrics_temp/metrics.txt

scone fspf create "$FSPF_DIR/fspf.pb"
scone fspf addr "$FSPF_DIR/fspf.pb" / --kernel / --not-protected
scone fspf addr "$FSPF_DIR/fspf.pb" "$ENCRYPTED_DIR" --kernel "$ENCRYPTED_DIR" --encrypted
scone fspf addf "$FSPF_DIR/fspf.pb" "$ENCRYPTED_DIR" "$ORIGINAL_DIR" "$ENCRYPTED_DIR"
scone fspf addr "$FSPF_DIR/fspf.pb" "$METRICS_DIR" --kernel "$METRICS_DIR" --authenticated
scone fspf addf "$FSPF_DIR/fspf.pb" "$METRICS_DIR" "/metrics_temp" "$METRICS_DIR"
scone fspf encrypt "$FSPF_DIR/fspf.pb" > "$FSPF_DIR/keytag.out"