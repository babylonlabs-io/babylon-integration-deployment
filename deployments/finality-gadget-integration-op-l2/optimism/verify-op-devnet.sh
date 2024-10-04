#!/bin/bash
set -euo pipefail

# $1 is the flag to represent if the OP chain is deployed on the local L1 chain
if [ "$1" = true ]; then
  # check if L1 is running
  echo "Checking if L1 is running..."
  L1_CHAIN_ID_RESULT=$(curl -s -X POST -H 'Content-Type: application/json' \
    -d '{"jsonrpc": "2.0", "method": "eth_chainId", "params": [], "id": 1}' \
    http://localhost:8545 | jq -r '.result' | xargs printf '%d\n')
  if [ "$L1_CHAIN_ID_RESULT" = 900 ]; then
    echo "L1 is running and the chain id is $L1_CHAIN_ID_RESULT"
  else
    echo "ERROR: L1 is not running because the chain id is not responding correctly"
  fi
  # set the L2 chain id for op-devnet
  L2_CHAIN_ID=901
fi

# check if L2 op-geth is running
echo "Checking if L2 op-geth is running..."
L2_CHAIN_ID_RESULT=$(curl -s -X POST -H 'Content-Type: application/json' \
    -d '{"jsonrpc": "2.0", "method": "eth_chainId", "params": [], "id": 1}' \
    http://localhost:9545 | jq -r '.result' | xargs printf '%d\n')
if [ "$L2_CHAIN_ID_RESULT" = "$L2_CHAIN_ID" ]; then
    echo "L2 op-geth is running and the chain id is $L2_CHAIN_ID"
else
    echo "ERROR: L2 op-geth is not running because the chain id is not responding correctly"
fi

# check if L2 op-node is running
echo "Checking if L2 op-node is running..."
curl -s -X POST -H "Content-Type: application/json" \
    --data '{"jsonrpc":"2.0","method":"optimism_syncStatus","params":[],"id":1}' \
    http://localhost:7545 | \
    jq '.result | {
        head_l1_number: .head_l1.number,
        safe_l1_number: .safe_l1.number,
        finalized_l1_number: .finalized_l1.number,
        unsafe_l2_number: .unsafe_l2.number,
        safe_l2_number: .safe_l2.number,
        finalized_l2_number: .finalized_l2.number
    }'
if [ $? -ne 0 ]; then
    echo "ERROR: L2 op-node is not running because the RPC is not responding correctly"
fi
echo