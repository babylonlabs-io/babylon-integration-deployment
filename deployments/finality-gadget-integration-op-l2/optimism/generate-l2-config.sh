#!/bin/bash
set -euo pipefail

# Go to the OP node directory
OP_NODE_DIR=$OP_DIR/op-node
echo "OP_NODE_DIR: $OP_NODE_DIR"
cd $OP_NODE_DIR

# Create genesis files
echo "Creating genesis files..."
go run cmd/main.go genesis l2 \
  --deploy-config ./.deploy/sepolia-devnet.json \
  --l1-deployments ./.deploy/deployments-artifact.json \
  --outfile.l2 ./.deploy/genesis.json \
  --outfile.rollup ./.deploy/rollup.json \
  --l1-rpc $L1_RPC_URL
echo

# Create an authentication key
echo "Creating an authentication key..."
openssl rand -hex 32 > ./.deploy/test-jwt-secret.txt

