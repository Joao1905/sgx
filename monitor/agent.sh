#!/bin/bash
cd "$(dirname "$0")"
BASE_DIR="$(pwd)"

python3.9 $BASE_DIR/workers/agent.py
