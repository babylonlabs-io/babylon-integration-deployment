#!/bin/bash
set -euo pipefail

# check if the Babylon FP already exists
EXISTING_BBN_FP_MONIKER=$(docker exec finality-provider /bin/sh \
    -c "/bin/fpd list-finality-providers" \
    | jq '.finality_providers[0].description.moniker')
EXISTING_BBN_FP_EOTS_PK_HEX=$(docker exec finality-provider /bin/sh \
    -c "/bin/fpd list-finality-providers" \
    | jq -r '.finality_providers[0].btc_pk_hex')
if [ "$EXISTING_BBN_FP_MONIKER" == "$BBN_FP_MONIKER" ]; then
    echo "Babylon finality provider already exists with \
moniker: $EXISTING_BBN_FP_MONIKER and \
EOTS PK: $EXISTING_BBN_FP_EOTS_PK_HEX"
    exit 0
fi

# create FP for Babylon
echo "Creating Babylon finality provider..."
BBN_FP_EOTS_PK_HEX=$(docker exec finality-provider /bin/sh -c "
    /bin/fpd create-finality-provider \
    --key-name $BBN_FP_KEY_NAME \
    --chain-id $BABYLON_CHAIN_ID \
    --moniker $BBN_FP_MONIKER" | jq -r '.btc_pk_hex')
echo "BBN_FP_EOTS_PK_HEX: $BBN_FP_EOTS_PK_HEX"
echo
sleep 5

echo "Registering Babylon finality provider..."
docker exec finality-provider /bin/sh -c "
    /bin/fpd register-finality-provider $BBN_FP_EOTS_PK_HEX"
echo
sleep 5

# Get the public keys of the Babylon FP
echo "Created Babylon finality provider"
BBN_FP_BTC_PK=$(docker exec btc-staker /bin/sh -c "
    /bin/stakercli daemon babylon-finality-providers" | jq -r '.finality_providers[].bitcoin_public_Key')
echo "BTC PK of Babylon finality provider: $BBN_FP_BTC_PK"
echo