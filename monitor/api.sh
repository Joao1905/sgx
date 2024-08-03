#!/bin/bash
cd "$(dirname "$0")"
BASE_DIR="$(pwd)"

flask --app $BASE_DIR/workers/api.py run &
