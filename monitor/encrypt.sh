HOST_APP=/hostapp
ORIGINAL_DIR=/sgx/monitor
ENCRYPTED_DIR=/sgx/encrypted
FSPF_DIR=/sgx/fspf

rm -rf $ORIGINAL_DIR
rm -rf $ENCRYPTED_DIR
rm -rf $FSPF_DIR

mkdir -p $ORIGINAL_DIR
mkdir -p $ENCRYPTED_DIR
mkdir -p $FSPF_DIR
cp -R $HOST_APP $ORIGINAL_DIR

scone fspf create "$FSPF_DIR/fspf.pb"
scone fspf addr "$FSPF_DIR/fspf.pb" / --kernel / --not-protected
scone fspf addr "$FSPF_DIR/fspf.pb" "$ENCRYPTED_DIR" --kernel "$ENCRYPTED_DIR" --encrypted
scone fspf addf "$FSPF_DIR/fspf.pb" "$ENCRYPTED_DIR" "$ORIGINAL_DIR" "$ENCRYPTED_DIR"
scone fspf encrypt "$FSPF_DIR/fspf.pb" > "$FSPF_DIR/keytag.out"