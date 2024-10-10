#!/usr/bin/env bash

ORIGINAL_DIR=/original
ENCRYPTED_DIR=/sgx/monitor
METRICS_DIR=/metrics
FSPF_DIR=/fspf

mkdir -p $ENCRYPTED_DIR
mkdir -p $FSPF_DIR

scone fspf create "$FSPF_DIR/fspf.pb"
scone fspf addr "$FSPF_DIR/fspf.pb" "$METRICS_DIR" --ephemeral --encrypted
scone fspf addr "$FSPF_DIR/fspf.pb" / --kernel / --not-protected
scone fspf addr "$FSPF_DIR/fspf.pb" "$ENCRYPTED_DIR" --kernel "$ENCRYPTED_DIR" --encrypted
scone fspf addf "$FSPF_DIR/fspf.pb" "$ENCRYPTED_DIR" "$ORIGINAL_DIR" "$ENCRYPTED_DIR"
scone fspf encrypt "$FSPF_DIR/fspf.pb" > "$FSPF_DIR/keytag.out"