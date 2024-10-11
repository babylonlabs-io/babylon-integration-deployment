#!/bin/bash
set -euo pipefail

OP_DIR=$1
OP_DEPLOY_DIR=$2
source $OP_DEPLOY_DIR/utils.sh
DEVNET_DIR=$OP_DIR/.devnet
CONTRACTS_BEDROCK_DIR=$OP_DIR/packages/contracts-bedrock
DEPLOYMENT_DIR=$CONTRACTS_BEDROCK_DIR/deployments/devnetL1
FORGE_L1_DUMP_PATH=$CONTRACTS_BEDROCK_DIR/state-dump-900.json
OP_NODE_DIR=$OP_DIR/op-node
OPS_BEDROCK_DIR=$OP_DIR/ops-bedrock
DEPLOY_CONFIG_DIR=$CONTRACTS_BEDROCK_DIR/deploy-config
DEVNET_CONFIG_PATH=$DEPLOY_CONFIG_DIR/devnetL1.json
DEVNET_CONFIG_TEMPLATE_PATH=$DEPLOY_CONFIG_DIR/devnetL1-template.json
L1_DEPLOYMENT_PATH=$DEPLOYMENT_DIR/.deploy
GENESIS_L1_PATH=$DEVNET_DIR/genesis-l1.json
ALLOCS_L1_PATH=$DEVNET_DIR/allocs-l1.json
ADDRESSES_JSON_PATH=$DEVNET_DIR/addresses.json

echo "Creating $DEVNET_DIR directory..."
mkdir -p $DEVNET_DIR

devnet_l1_allocs() {
    echo "Generating L1 genesis allocs..."
    init_devnet_l1_deploy_config false
    cd $CONTRACTS_BEDROCK_DIR
    DEPLOYMENT_OUTFILE=$L1_DEPLOYMENT_PATH \
    DEPLOY_CONFIG_PATH=$DEVNET_CONFIG_PATH \
      forge script $CONTRACTS_BEDROCK_DIR/scripts/deploy/Deploy.s.sol:Deploy \
      --sig 'runWithStateDump()' \
      --sender $GS_SEQUENCER_ADDRESS
    
    mv $FORGE_L1_DUMP_PATH $ALLOCS_L1_PATH
    cp $L1_DEPLOYMENT_PATH $ADDRESSES_JSON_PATH
}

init_devnet_l1_deploy_config() {
    echo "Initializing devnet L1 deploy config..."
    cp $DEVNET_CONFIG_TEMPLATE_PATH $DEVNET_CONFIG_PATH
    # $1 flag if l1 genesis timestamp should be updated
    if [ $1 = "true" ]; then
        timestamp=$(printf '0x%x' $(date +%s))
        echo "Updating l1 genesis timestamp with $timestamp..."
        jq --arg timestamp "$timestamp" '.l1GenesisBlockTimestamp = $timestamp' $DEVNET_CONFIG_PATH > temp.json && mv temp.json $DEVNET_CONFIG_PATH
    fi
    if $DEVNET_L2OO; then
        echo "Setting useFaultProofs to false..."
        jq ".useFaultProofs = false" $DEVNET_CONFIG_PATH > temp.json && mv temp.json $DEVNET_CONFIG_PATH
    fi
    if $DEVNET_ALTDA; then
        echo "Setting useAltDA to true..."
        jq ".useAltDA = true" $DEVNET_CONFIG_PATH > temp.json && mv temp.json $DEVNET_CONFIG_PATH
    fi
    if $GENERIC_ALTDA; then
        echo "Setting daCommitmentType to GenericCommitment..."
        jq ".daCommitmentType = \"GenericCommitment\"" $DEVNET_CONFIG_PATH > temp.json && mv temp.json $DEVNET_CONFIG_PATH
    fi
}

# Check if L1 genesis already exists
if [ -f "$GENESIS_L1_PATH" ]; then
    echo "L1 genesis already generated."
else
    echo "Generating L1 genesis..."
    
    # Check if L1 allocs need to be generated
    if [ ! -f "$ALLOCS_L1_PATH" ] || [ DEVNET_L2OO ] || [ DEVNET_ALTDA ]; then
        devnet_l1_allocs
        echo "L1 allocs generated at $ALLOCS_L1_PATH"
    else
        echo "Re-using existing L1 allocs."
    fi

    init_devnet_l1_deploy_config true
    # Generate L1 genesis
    cd $OP_NODE_DIR
    go run cmd/main.go genesis l1 \
        --deploy-config "$DEVNET_CONFIG_PATH" \
        --l1-allocs "$ALLOCS_L1_PATH" \
        --l1-deployments "$ADDRESSES_JSON_PATH" \
        --outfile.l1 "$GENESIS_L1_PATH"
    echo "L1 genesis file generated at $GENESIS_L1_PATH"

    # Generate beacon genesis
    echo "Generating beacon genesis..."
    cd $OPS_BEDROCK_DIR
    chmod +x $OPS_BEDROCK_DIR/l1-generate-beacon-genesis.sh
    $OPS_BEDROCK_DIR/l1-generate-beacon-genesis.sh
    # Check if the script failed
    if [ $? -ne 0 ]; then
        echo "Failed to run l1-generate-beacon-genesis.sh script"
    else
        echo "Beacon genesis generated."
    fi
fi

# Start L1 chain
echo "Starting L1 chain..."
PWD=$OPS_BEDROCK_DIR docker compose up -d l1 l1-bn l1-vc

# Wait for the L1 chain to be available
echo "Waiting for L1 chain to be available..."
wait_up 8545
wait_up 5052
echo