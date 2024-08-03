#!/bin/bash
cd "$(dirname "$0")"
BASE_DIR="$(pwd)"

export METRICS_PATH="${BASE_DIR}/metrics.txt"
export X_API_KEY="defaultkey" 