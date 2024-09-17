#!/bin/bash
set -euo pipefail

# Check if grpcurl is installed
if ! command -v grpcurl &> /dev/null
then
    echo "grpcurl could not be found, installing..."
    # Install grpcurl using go install
    go install github.com/fullstorydev/grpcurl/cmd/grpcurl@latest
else
    echo "grpcurl is already installed."
fi
grpcurl --version
echo

echo "Wait a few minutes to verify Babylon finality gadget integration..."
echo

FINALITY_GADGET_DIR=$1
PROTO_FILE="$FINALITY_GADGET_DIR/proto/finalitygadget.proto"
PROTO_PATH="$FINALITY_GADGET_DIR/proto"
GRPC_SERVER="localhost:50051"

echo "Fetching the OP L2 sync status..."
while true; do
  OP_L2_SYNC_STATUS=$(curl -s -X POST -H "Content-Type: application/json" \
      --data '{"jsonrpc":"2.0","method":"optimism_syncStatus","params":[],"id":1}' \
      http://localhost:7545)
  OP_L2_SYNC_STATUS_FINALIZED_L2_HASH=$(echo $OP_L2_SYNC_STATUS | jq -r '.result.finalized_l2.hash')
  OP_L2_SYNC_STATUS_FINALIZED_L2_NUMBER=$(echo $OP_L2_SYNC_STATUS | jq -r '.result.finalized_l2.number')
  OP_L2_SYNC_STATUS_FINALIZED_L2_TIMESTAMP=$(echo $OP_L2_SYNC_STATUS | jq -r '.result.finalized_l2.timestamp')

  echo "OP L2 sync status - finalized L2 block number: $OP_L2_SYNC_STATUS_FINALIZED_L2_NUMBER"

  if [ "$OP_L2_SYNC_STATUS_FINALIZED_L2_NUMBER" -gt 50 ]; then
      echo "It is time to verify the latest finalized block"
      break
  else
      sleep 15
  fi
done
sleep 5
echo

echo "Querying if the latest finalized block is Babylon finalized..."
echo "OP L2 block number: $OP_L2_SYNC_STATUS_FINALIZED_L2_NUMBER"
echo "OP L2 block hash: $OP_L2_SYNC_STATUS_FINALIZED_L2_HASH"
echo "OP L2 block timestamp: $OP_L2_SYNC_STATUS_FINALIZED_L2_TIMESTAMP"
BLOCK_IS_BABYLON_FINALIZED=$(grpcurl -proto $PROTO_FILE \
  -import-path $PROTO_PATH \
  -plaintext \
  -d '{
    "block": {
      "block_hash": "'"$OP_L2_SYNC_STATUS_FINALIZED_L2_HASH"'",
      "block_height": '"$OP_L2_SYNC_STATUS_FINALIZED_L2_NUMBER"',
      "block_timestamp": '"$OP_L2_SYNC_STATUS_FINALIZED_L2_TIMESTAMP"'
    }
  }' \
  $GRPC_SERVER \
  proto.FinalityGadget/QueryIsBlockBabylonFinalized | jq -r '.isFinalized')
echo

if [ "$BLOCK_IS_BABYLON_FINALIZED" == "true" ]; then
  echo "The latest finalized block $OP_L2_SYNC_STATUS_FINALIZED_L2_NUMBER is Babylon finalized"
else
  echo "The latest finalized block $OP_L2_SYNC_STATUS_FINALIZED_L2_NUMBER is not Babylon finalized"
  exit 1
fi
echo