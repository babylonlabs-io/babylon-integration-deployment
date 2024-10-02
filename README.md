# Babylon Integration Deployment

This repository contains artifacts and instructions for setting up and running a Babylon network that integrates with various consumer chains.

## Prerequisites

1. **Docker Desktop**: Install from [Docker's official website](https://docs.docker.com/desktop/).

2. **Make**: Required for building service binaries. Installation guide available [here](https://sp21.datastructur.es/materials/guides/make-install.html).

3. **Repository Setup**:
   ```shell
   git clone git@github.com:babylonlabs-io/babylon-integration-deployment.git
   git submodule init && git submodule update
   ```

## Deployment Scenarios

Scenarios are located in the [deployments](deployments/) directory:

- [BTC Staking Integration (bitcoind backend)](deployments/btc-staking-integration-bitcoind): Babylon network with BTC Staking and Timestamping, using a bitcoind-based BTC regression testnet.
- [Finality Gadget Integration with OP chain](deployments/finality-gadget-integration-op-l2): Finality gadget integration with a Babylon testnet, a a bitcoind-based BTC regtest, and a OP devnet.
