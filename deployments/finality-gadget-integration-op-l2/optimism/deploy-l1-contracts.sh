#!/bin/bash
set -euo pipefail

OP_DIR=$1
echo "OP_DIR: $OP_DIR"
echo

# Go to the OP contracts directory
OP_CONTRACTS_DIR=$OP_DIR/packages/contracts-bedrock
echo "OP_CONTRACTS_DIR: $OP_CONTRACTS_DIR"
cd $OP_CONTRACTS_DIR

# Install contracts dependencies
echo "Installing the dependencies for the smart contracts..."
just install
echo

# Deploy the L1 contracts
echo "Deploying the L1 contracts..."
forge script scripts/Deploy.s.sol:Deploy --private-key $GS_ADMIN_PRIVATE_KEY --broadcast --rpc-url $L1_RPC_URL --slow
echo