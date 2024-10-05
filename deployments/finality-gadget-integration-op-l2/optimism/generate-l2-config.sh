#!/bin/bash
set -euo pipefail

OP_DIR=$1
OP_DEPLOY_DIR=$2/.deploy
DEPLOY_CONFIG_PATH=${OP_DIR}/packages/contracts-bedrock/deploy-config/sepolia-devnet-${L2_CHAIN_ID}.json
DEPLOYMENT_OUTFILE=${OP_DIR}/packages/contracts-bedrock/deployments/sepolia-devnet-${L2_CHAIN_ID}.json
L2_ALLOCS_OUTFILE=${OP_DEPLOY_DIR}/l2-allocs.json
L2_GENESIS_OUTFILE=${OP_DEPLOY_DIR}/genesis.json
L2_ROLLUP_OUTFILE=${OP_DEPLOY_DIR}/rollup.json
JWT_SECRET_PATH=${OP_DEPLOY_DIR}/test-jwt-secret.txt

# Create deployment directory that will hold configuration files
mkdir -p ${OP_DEPLOY_DIR} && chmod -R 777 ${OP_DEPLOY_DIR}

# Go to the OP contracts directory
OP_CONTRACTS_DIR=$OP_DIR/packages/contracts-bedrock
echo "OP_CONTRACTS_DIR: $OP_CONTRACTS_DIR"
cd $OP_CONTRACTS_DIR

# Dump the L2 genesis allocs (aka "state dump")
echo "Dumping the L2 genesis allocs..."
CONTRACT_ADDRESSES_PATH=${DEPLOYMENT_OUTFILE} \
DEPLOY_CONFIG_PATH=${DEPLOY_CONFIG_PATH} \
STATE_DUMP_PATH=${L2_ALLOCS_OUTFILE} \
  forge script $OP_CONTRACTS_DIR/scripts/L2Genesis.s.sol:L2Genesis \
  --sig 'runWithStateDump()'
echo "L2 genesis allocs dumped at ${L2_ALLOCS_OUTFILE}"
echo

# Go to the OP node directory
OP_NODE_DIR=$OP_DIR/op-node
echo "OP_NODE_DIR: $OP_NODE_DIR"
cd $OP_NODE_DIR

# Create genesis files
echo "Creating genesis files..."
go run cmd/main.go genesis l2 \
  --deploy-config ${DEPLOY_CONFIG_PATH} \
  --l1-deployments ${DEPLOYMENT_OUTFILE} \
  --l2-allocs ${L2_ALLOCS_OUTFILE} \
  --outfile.l2 ${L2_GENESIS_OUTFILE} \
  --outfile.rollup ${L2_ROLLUP_OUTFILE} \
  --l1-rpc $L1_RPC_URL
echo "L2 genesis files created at ${L2_GENESIS_OUTFILE}"
echo

# Create an authentication key
echo "Creating an authentication key..."
openssl rand -hex 32 > ${JWT_SECRET_PATH}
echo "Authentication key created at ${JWT_SECRET_PATH}"
echo