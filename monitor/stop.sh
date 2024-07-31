#!/bin/bash
if [[ "${AGENT_PID}" != "" ]]; then
    echo "Killing ${AGENT_PID}"
    kill $AGENT_PID
fi

if [[ "${AGENT_PID}" != "" ]]; then
    echo "Killing ${API_PID}"
    kill $API_PID
fi

echo "Unsetting AGENT_PID and API_PID env vars"
unset AGENT_PID
unset API_PID
