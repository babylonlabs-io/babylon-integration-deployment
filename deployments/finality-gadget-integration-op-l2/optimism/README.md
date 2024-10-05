## Creating the OP chain testnet

This deployment is used to create the OP chain testnet on the local L1 chain or the Sepolia testnet.

TODO: update the make commands to the new structure.

Deploy the OP chain testnet on the local L1 chain:

```bash
make start-op-devnet
```

Deploy the OP chain testnet on the Sepolia testnet:

```bash
make start-op-chain-sepolia
```

### Detailed description for the deployment steps on the Sepolia testnet

1. The dependencies(`go`, `foundry`, and `just`) would be checked and installed with the `install-deps.sh` script. This script can be used for the deployment on both the L1 chain and the Sepolia testnet.

    ```bash
    install-deps.sh <OP_MONOREPO_DIR>
    ```

2. Four addresses and their private keys are needed when setting up the OP chain. 

    Run the Optimism Monorepo's `wallet.sh` script to generate the addresses. 

    ```bash
    cd <OP_MONOREPO_DIR>
    ./packages/contracts-bedrock/scripts/getting-started/wallet.sh
    ```

    Also, please send Sepolia ETH to the Admin, Proposer, and Batcher addresses.

3. Copy the `env.example` file to `.env` and set the environment variables.

    ```bash
    cp env.example .env
    ```

    Also, copy the output from the previous step and paste it into the `.env` file. **Note**: Remove the `export` from the output.

4. Generate the deployment configuration. 

    Run the `generate-deploy-config.sh` script to generate it.

    ```bash
    generate-deploy-config.sh <OP_MONOREPO_DIR>
    ```

5. Deploy the L1 contracts for the functionality of the OP chain. 

    Run the `deploy-l1-contracts.sh` script to deploy them.

    ```bash
    deploy-l1-contracts.sh <OP_MONOREPO_DIR>
    ```

6. Generate the L2 configuration file. 

    Run the `generate-l2-config.sh` script to generate it.

    ```bash
    generate-l2-config.sh <OP_MONOREPO_DIR> <OP_DEPLOYMENT_DIR>
    ```

7. Launch the OP chain. 

    Run the `launch-l2.sh` script to start the OP chain.

    ```bash
    launch-l2.sh <OP_MONOREPO_DIR> <OP_DEPLOYMENT_DIR>
    ```

### Launch the local L1 chain

This is only used to test the deployment of the OP chain before deploying it on the Sepolia testnet.

```bash
make start-local-l1-chain
```

**NOTE**: If you want to test the OP deployment with the local L1 chain, you MUST reload this variable to ensure the salt is regenerated and the contracts are deployed to new addresses (otherwise deployment will fail).

```bash
export IMPL_SALT=$(openssl rand -hex 32)
```