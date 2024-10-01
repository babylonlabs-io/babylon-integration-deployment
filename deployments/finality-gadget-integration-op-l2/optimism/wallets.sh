#!/usr/bin/env bash

# This script is used to generate the four wallets that are used in the deployment.

# Generate wallets
wallet1=$(cast wallet new)
wallet2=$(cast wallet new)
wallet3=$(cast wallet new)
wallet4=$(cast wallet new)

# Grab wallet addresses
address1=$(echo "$wallet1" | awk '/Address/ { print $2 }')
address2=$(echo "$wallet2" | awk '/Address/ { print $2 }')
address3=$(echo "$wallet3" | awk '/Address/ { print $2 }')
address4=$(echo "$wallet4" | awk '/Address/ { print $2 }')

# Grab wallet private keys
key1=$(echo "$wallet1" | awk '/Private key/ { print $3 }')
key2=$(echo "$wallet2" | awk '/Private key/ { print $3 }')
key3=$(echo "$wallet3" | awk '/Private key/ { print $3 }')
key4=$(echo "$wallet4" | awk '/Private key/ { print $3 }')

# Print out the environment variables to copy
echo "# Copy the following into your .env file:"
echo
echo "# Admin account"
echo "GS_ADMIN_ADDRESS=$address1"
echo "GS_ADMIN_PRIVATE_KEY=$key1"
echo
echo "# Batcher account"
echo "GS_BATCHER_ADDRESS=$address2"
echo "GS_BATCHER_PRIVATE_KEY=$key2"
echo
echo "# Proposer account"
echo "GS_PROPOSER_ADDRESS=$address3"
echo "GS_PROPOSER_PRIVATE_KEY=$key3"
echo
echo "# Sequencer account"
echo "GS_SEQUENCER_ADDRESS=$address4"
echo "GS_SEQUENCER_PRIVATE_KEY=$key4"