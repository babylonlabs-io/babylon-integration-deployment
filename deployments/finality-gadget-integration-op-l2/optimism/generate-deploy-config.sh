#!/bin/bash
set -euo pipefail

OP_DIR=$1
DEPLOY_CONFIG_PATH=${OP_DIR}/packages/contracts-bedrock/deploy-config

# Run the Optimism Monorepo's config.sh script
# which will generate the getting-started.json configuration file
echo "Generating deployment configuration for OP L2..."
${OP_DIR}/packages/contracts-bedrock/scripts/getting-started/config.sh
# Check if the config.sh script failed
if [ $? -ne 0 ]; then
    echo "Failed to run config.sh script"
    exit 1
fi

# Check optional environment variables
DEVNET_L2OO=${DEVNET_L2OO:-true}
DEVNET_ALTDA=${DEVNET_ALTDA:-false}
GENERIC_ALTDA=${GENERIC_ALTDA:-false}
if [ "$DEVNET_L2OO" = true ]; then
  USE_FAULT_PROOFS=false
else
  USE_FAULT_PROOFS=true
fi

# Create the config file with the additional fields, e.g. useFaultProofs
GETTING_STARTED_OUTFILE=${DEPLOY_CONFIG_PATH}/getting-started.json
DEPLOY_CONFIG_OUTFILE=${DEPLOY_CONFIG_PATH}/sepolia-devnet-${L2_CHAIN_ID}.json
jq ".useFaultProofs = ${USE_FAULT_PROOFS}" ${GETTING_STARTED_OUTFILE} > ${DEPLOY_CONFIG_OUTFILE}
rm ${GETTING_STARTED_OUTFILE}
echo "Deployment configuration generated at ${DEPLOY_CONFIG_OUTFILE}"
echo