#!/bin/bash
set -euo pipefail

FINALITY_GADGET_DIR=$1
PROTO_FILE="$FINALITY_GADGET_DIR/proto/finalitygadget.proto"
PROTO_PATH="$FINALITY_GADGET_DIR/proto"
GRPC_SERVER="localhost:50051"

# Call the QueryLatestFinalizedBlock method
FG_LATEST_FINALIZED_BLOCK=$(grpcurl -proto $PROTO_FILE \
  -import-path $PROTO_PATH \
  -plaintext -d '{}' \
  $GRPC_SERVER \
  proto.FinalityGadget/QueryLatestFinalizedBlock)
FG_LATEST_FINALIZED_BLOCK_HASH=$(echo $FG_LATEST_FINALIZED_BLOCK | jq -r '.block.blockHash')
FG_LATEST_FINALIZED_BLOCK_HEIGHT=$(echo $FG_LATEST_FINALIZED_BLOCK | jq -r '.block.blockHeight')
FG_LATEST_FINALIZED_BLOCK_TIMESTAMP=$(echo $FG_LATEST_FINALIZED_BLOCK | jq -r '.block.blockTimestamp')
echo

# Fetch the OP L2 sync status
OP_L2_SYNC_STATUS=$(curl -s -X POST -H "Content-Type: application/json" \
    --data '{"jsonrpc":"2.0","method":"optimism_syncStatus","params":[],"id":1}' \
    http://localhost:7545)
OP_L2_SYNC_STATUS_FINALIZED_L2_HASH=$(echo $OP_L2_SYNC_STATUS | jq -r '.result.finalized_l2.hash')
OP_L2_SYNC_STATUS_FINALIZED_L2_NUMBER=$(echo $OP_L2_SYNC_STATUS | jq -r '.result.finalized_l2.number')
OP_L2_SYNC_STATUS_FINALIZED_L2_TIMESTAMP=$(echo $OP_L2_SYNC_STATUS | jq -r '.result.finalized_l2.timestamp')
echo

# Verify and print the results
if [ "$FG_LATEST_FINALIZED_BLOCK_HASH" == "$OP_L2_SYNC_STATUS_FINALIZED_L2_HASH" ] && \
   [ "$FG_LATEST_FINALIZED_BLOCK_HEIGHT" == "$OP_L2_SYNC_STATUS_FINALIZED_L2_NUMBER" ] && \
   [ "$FG_LATEST_FINALIZED_BLOCK_TIMESTAMP" == "$OP_L2_SYNC_STATUS_FINALIZED_L2_TIMESTAMP" ]; then
  echo "The latest finalized block is the same between the finality gadget and OP L2:"
  echo "blockHash: $FG_LATEST_FINALIZED_BLOCK_HASH"
  echo "blockHeight: $FG_LATEST_FINALIZED_BLOCK_HEIGHT"
  echo "blockTimestamp: $FG_LATEST_FINALIZED_BLOCK_TIMESTAMP"
else
  echo "The latest finalized block is different between the finality gadget and OP L2:"
  echo "Finality Gadget - Hash: $FG_LATEST_FINALIZED_BLOCK_HASH, Height: $FG_LATEST_FINALIZED_BLOCK_HEIGHT, Timestamp: $FG_LATEST_FINALIZED_BLOCK_TIMESTAMP"
  echo "OP L2 - Hash: $OP_L2_SYNC_STATUS_FINALIZED_L2_HASH, Number: $OP_L2_SYNC_STATUS_FINALIZED_L2_NUMBER, Timestamp: $OP_L2_SYNC_STATUS_FINALIZED_L2_TIMESTAMP"
  exit 1
fi