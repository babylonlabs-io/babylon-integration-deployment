#!/bin/sh
GIT_TOPLEVEL=$(git rev-parse --show-toplevel)
# Create new directory that will hold node and services' configuration
mkdir -p .testnets && chmod o+w .testnets

# Create separate subpaths for each component and copy relevant configuration
rm -rf .testnets
mkdir -p .testnets/bitcoin
mkdir -p .testnets/bitcoin-signer
mkdir -p .testnets/rabbitmq_data
mkdir -p .testnets/staking-indexer/data .testnets/staking-indexer/logs
mkdir -p .testnets/mongo
mkdir -p .testnets/staking-api-service
mkdir -p .testnets/staking-expiry-checker
mkdir -p .testnets/unbonding-pipeline
mkdir -p .testnets/covenant-signer

cp artifacts/sid.conf .testnets/staking-indexer/sid.conf
cp artifacts/global-params.json .testnets/
cp artifacts/finality-providers.json .testnets/
cp artifacts/staking-api-service-config.yml .testnets/staking-api-service
cp artifacts/init-mongo.sh .testnets/mongo
cp artifacts/staking-expiry-checker-config.yml .testnets/staking-expiry-checker
cp artifacts/unbonding-pipeline-config.toml .testnets/unbonding-pipeline
cp artifacts/covenant-signer-config.toml .testnets/covenant-signer
cp artifacts/covenant-signer.dat .testnets/bitcoin-signer
