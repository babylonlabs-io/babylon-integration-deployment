#!/bin/bash
set -euo pipefail

OP_DIR=$1

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
DEPLOYMENT_OUTFILE=${OP_DIR}/packages/contracts-bedrock/deployments/sepolia-devnet-${L2_CHAIN_ID}.json \
DEPLOY_CONFIG_PATH=${OP_DIR}/packages/contracts-bedrock/deploy-config/sepolia-devnet-${L2_CHAIN_ID}.json \
  forge script $OP_CONTRACTS_DIR/scripts/deploy/Deploy.s.sol:Deploy \
  --private-key "$GS_ADMIN_PRIVATE_KEY" \
  --broadcast --rpc-url "$L1_RPC_URL" --slow
echo