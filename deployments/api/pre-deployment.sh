#!/bin/sh

echo "Running pre-deployment script"

# Create new directory that will hold node and services' configuration
mkdir -p .testnets && chmod o+w .testnets

# Create separate subpaths for each component and copy relevant configuration
mkdir -p .testnets/api
mkdir -p .testnets/poller

cp artifacts/api-config.yml .testnets/api/config.yml
cp artifacts/poller-config.yml .testnets/poller/config.yml
cp ../../babylon-api/sample-chain-registry.json .testnets/api/chain-registry.json 
cp ../../rpc-poller/sample-chain-registry.json .testnets/poller/chain-registry.json

echo "Completed pre-deployment script"