# Babylon Integration Deployment

This repository contains artifacts and instructions for setting up and running a Babylon network that integrates with various consumer chains.

## Prerequisites

1. **Docker Desktop**: Install from [Docker's official website](https://docs.docker.com/desktop/).

2. **Make**: Required for building service binaries. Installation guide available [here](https://sp21.datastructur.es/materials/guides/make-install.html).

3. **GitHub SSH Key**:
   - Create a non-passphrase-protected SSH key.
   - Add it to GitHub ([instructions](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account)).
   - Export the key path:
     ```shell
     export BBN_PRIV_DEPLOY_KEY=FULL_PATH_TO_PRIVATE_KEY/.ssh/id_ed25519
     ```
   - For more details, see [babylon-api/README.md#installation](babylon-api/README.md#installation).

4. **Repository Setup**:
   ```shell
   git clone git@github.com:babylonlabs-io/babylon-integration-deployment.git
   git submodule init && git submodule update
   ```

## Deployment Scenarios

Scenarios are located in the [deployments](deployments/) directory:

- [BTC Staking Integration (bitcoind backend)](deployments/btc-staking-integration-bitcoind): Babylon network with BTC Staking and Timestamping, using a bitcoind-based BTC regression testnet.
