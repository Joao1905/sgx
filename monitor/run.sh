#!/bin/bash
BASE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export METRICS_PATH="${BASE_DIR}/metrics.txt"

if [[ "${AGENT_PID}" != "" || "${API_PID}" != "" ]]; then
    echo "Process already running with ids ${AGENT_PID} and ${API_PID}"
    echo 
    return
fi

python3 workers/agent.py &
export AGENT_PID=$!

flask --app ./workers/api.py run &
export API_PID=$!

echo "Started processes ${AGENT_PID} and ${API_PID}"