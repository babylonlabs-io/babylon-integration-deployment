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

## Run the deployment with the Bitcoin Signet

1. Set up the environment variables, uncomment the Bitcoin section and update the values for the Bitcoin Signet:

```bash
cd deployments/finality-gadget-integration-op-l2
cp .env.example .env
```

Bitcoin section:

```bash
BITCOIN_NETWORK=
BITCOIN_RPC_PORT=
WALLET_PASS=
BTCSTAKER_PRIVKEY=
SLASHING_ADDRESS=
```

2. Start the deployment, run the following command from the root of the repository:

```bash
make start-deployment-finality-gadget-integration-op-l2-signet
```

An example of the expected output:

```bash
...
Please wait until the local Bitcoin node is fully synced with the signet network.
Note: syncing can take several hours to complete.
To check if the Bitcoin node is synced, run the following command:
cd /home/ubuntu/babylon-integration-deployment/deployments/finality-gadget-integration-op-l2 && ./verify-bitcoin-sync-balance.sh
Once synced and has at least 0.01 BTC, to create BTC delegations by running the following command:
cd /home/ubuntu/babylon-integration-deployment/deployments/finality-gadget-integration-op-l2 && ./create-btc-delegations.sh
```

3. To check if the Bitcoin node is synced, run the following command from the directory `finality-gadget-integration-op-l2`:

```bash
./verify-bitcoin-sync-balance.sh
```

An example of the expected output:

```bash
Checking if Bitcoin node is synced...
Bitcoin node is synced: 0.9999997708495327

Creating a wallet for btcstaker...
{
  "name": "btcstaker",
  "warnings": [
    "Wallet created successfully. The legacy wallet type is being deprecated and support for creating and opening legacy wallets will be removed in the future."
  ]
}
Unlocking btcstaker wallet...
Importing btcstaker private key, it would take several minutes to complete rescan...
Wallet btcstaker imported successfully

BTCStaker address: tb1qdfrvwahpgndfn8s7nkwhxlzwexgeahz5a2z9ul
BTCStaker balance is sufficient: 0.0114335 BTC
```

4. To check if the Vigilante reporter is running normally, run the following command from the directory `finality-gadget-integration-op-l2`:

```bash
./check-vigilante-reporter.sh
```

An example of the expected output:

```bash
2024-09-15T13:01:08.700311Z     info    Successfully started the vigilant reporter      {"module": "reporter"}
Found success message in vigilante-reporter container logs
vigilante-reporter container is running normally
```

5. To create BTC delegation, run the following command from the directory `finality-gadget-integration-op-l2`:

```bash
create-btc-delegations.sh
```

An example of the expected output:

```bash
Delegation was successful; staking tx hash is 45319b4e2bf40c844ed54c6fe36f3ab191207821273b80f3317dfbd36a5583b8

Wait a few minutes for the delegation to become active...
Active delegations count in Babylon: 0
...
Active delegations count in Babylon: 0
Active delegations count in Babylon: 1
BTC delegation has become active at 2024-09-15 13:29:31
```


6. Stop the deployment, run the following command from the root of the repository:

```bash
make stop-deployment-finality-gadget-integration-op-l2
```

### Notes

1. `BASE_HEADER_HEIGHT`, initialization for the babylon network, it should use the latest Bitcoin difficulty adjustment height
2. `btc-cache-size`, in the Vigilante reporter, it should not be less than the Bitcoin difficulty epoch 2016
3. `btc-confirmation-depth`, in the Vigilante moniter, it should not be less than 6
4. `min-staking-amount-sat`, in the init-babylon-accounts.sh, it should not be less than 10000 (same as Euphrates v0.5.0)



