#!/usr/bin/env bash

CURRENT_FOLDER=$( dirname -- "$( readlink -f -- "$0"; )"; )
CERT_FOLDER=$CURRENT_FOLDER/../certificate

openssl req -x509 -newkey rsa:4096 -days 36500 -nodes \
    -config "$CERT_FOLDER/manager-ca.conf" \
    -keyout "$CERT_FOLDER/manager-ca-key.pem" \
    -out "$CERT_FOLDER/manager-ca-cert.pem" \
    -extensions v3_req

openssl req -new -newkey rsa:4096 -nodes \
    -config "$CERT_FOLDER/manager-api.conf" \
    -keyout "$CERT_FOLDER/manager-api-key.pem" \
    -out "$CERT_FOLDER/manager-api-cert.csr" \
    -extensions v3_req

openssl x509 -req  -days 825 -sha256 -CAcreateserial \
    -in "$CERT_FOLDER/manager-api-cert.csr" \
    -CA "$CERT_FOLDER/manager-ca-cert.pem" \
    -CAkey "$CERT_FOLDER/manager-ca-key.pem" \
    -out "$CERT_FOLDER/manager-api-cert.pem" \
    -extfile "$CERT_FOLDER/manager-api.conf" \
    -extensions v3_req