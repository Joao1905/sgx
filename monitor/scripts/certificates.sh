#!/usr/bin/env bash

CURRENT_FOLDER=$( dirname -- "$( readlink -f -- "$0"; )"; )
CERT_FOLDER=$CURRENT_FOLDER/../certificate
MANAGER_CERT_FOLDER=$CURRENT_FOLDER/../../manager/certificate


openssl req -x509 -newkey rsa:4096 -days 36500 -nodes \
    -config "$CERT_FOLDER/monitor-ca.conf" \
    -keyout "$CERT_FOLDER/monitor-ca-key.pem" \
    -out "$CERT_FOLDER/monitor-ca-cert.pem" \
    -extensions v3_req

openssl req -new -newkey rsa:4096 -nodes \
    -config "$CERT_FOLDER/monitor-api.conf" \
    -keyout "$CERT_FOLDER/monitor-api-key.pem" \
    -out "$CERT_FOLDER/monitor-api-cert.csr" \
    -extensions v3_req

openssl x509 -req  -days 825 -sha256 -CAcreateserial \
    -in "$CERT_FOLDER/monitor-api-cert.csr" \
    -CA "$CERT_FOLDER/monitor-ca-cert.pem" \
    -CAkey "$CERT_FOLDER/monitor-ca-key.pem" \
    -out "$CERT_FOLDER/monitor-api-cert.pem" \
    -extfile "$CERT_FOLDER/monitor-api.conf" \
    -extensions v3_req