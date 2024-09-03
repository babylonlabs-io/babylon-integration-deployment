# Finality gadget integration - OP L2

The whole deployment process for the finality gadget integration with OP chain as follows steps:

1. spin up Babylon localnet
2. start Babylon FP
3. deploy finality gadget CW contract
4. start finality gadget server
5. spin up op-devnet
6. start OP consumer FP
7. register OP consumer
8. register Babylon and OP consumer FP
9. start covenant
10. create BTC delegation for FPs
11. verify Babylon finality

## How to run the deployment

0. Follow the [Prerequisites](../../README.md#prerequisites)

1. Set up the environment variables, update the values if needed:

```bash
cd deployments/finality-gadget-integration-op-l2
cp .env.example .env
```

2. Start the deployment and basic test, run the following command from the root of the repository:

```bash
make start-deployment-finality-gadget-integration-op-l2-demo
```

An example of the expected output:

```bash
...
Querying if the latest finalized block is Babylon finalized...
OP L2 block number: 79
OP L2 block hash: 0x85d80fe688528be0089ee234b89ff538083055a4f5a572a56fa880c752d320de
OP L2 block timestamp: 1724222870

The latest finalized block 79 is Babylon finalized
```

3. Stop the deployment, run the following command from the root of the repository:

```bash
make stop-deployment-finality-gadget-integration-op-l2
```