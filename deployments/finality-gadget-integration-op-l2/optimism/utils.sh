#!/bin/bash

wait_up() {
    local port=$1
    local retries=10
    local wait_time=1

    for i in $(seq 1 $retries); do
        if nc -z localhost $port; then
            echo "Port $port is available"
            return 0
        fi
        echo "Attempt $i: Port $port is not available yet. Waiting $wait_time seconds..."
        sleep $wait_time
    done

    echo "Error: Port $port did not become available after $retries attempts"
    return 1
}