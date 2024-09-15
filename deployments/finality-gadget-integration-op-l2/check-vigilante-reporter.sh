#!/bin/bash
set -euo pipefail

# Get the container ID
CONTAINER_ID=$(docker ps -qf "name=vigilante-reporter")

if [ -z "$CONTAINER_ID" ]; then
  echo "vigilante-reporter container is not running"
  exit 1
fi

# Check the container's state
STATE=$(docker inspect -f '{{.State.Status}}' $CONTAINER_ID)

if [ "$STATE" != "running" ]; then
  echo "vigilante-reporter container is not in running state. Current state: $STATE"
  exit 1
fi

# Check the container's logs for the success message
if docker logs $CONTAINER_ID 2>&1 | grep -i "Successfully started the vigilant reporter"; then
  echo "Found success message in vigilante-reporter container logs"
else
  echo "Success message not found in vigilante-reporter container logs"
  exit 1
fi

echo "vigilante-reporter container is running normally"
echo