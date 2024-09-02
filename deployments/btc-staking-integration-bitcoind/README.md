# BTC staking integration deployment

This deployment scenario demonstrates the integration of Babylon network with
BTC Staking and a Consumer chain, using a bitcoind private regtest network.
It showcases how the Consumer chain integrates with Babylon for BTC staking.

## Components

1. **Babylon Network**: Two nodes of a private Babylon network.
2. **BTC Regression Testnet**: A local Bitcoin testnet using bitcoind for
   testing and development.
3. **Babylon Finality Provider**: A finality provider on the Babylon chain.
4. **BTC Staker**: A BTC staker that re-stakes to the Babylon and Consumer
   finality provider.
5. **Consumer Chain**: A chain that is integrated with Babylon for BTC staking.
6. **Babylon Contracts**: Smart contracts on the Consumer chain.
7. **Consumer chain finality provider**: A finality provider on the Consumer
   chain.

## User stories covered

1. A Consumer chain creates an IBC channel with the Babylon chain to start the
   integration.
2. A Babylon finality provider registers to the Babylon chain.
3. A Consumer finality provider registers to the Consumer chain.
4. A BTC staker re-stakes BTC to the Babylon and Consumer finality providers.
5. The Consumer finality provider commits public randomness and submits finality
   signatures to the Consumer chain.
6. BTC staking finalises blocks of the Consumer chain.

## Usage

### Start the BTC staking integration demo

```shell
git submodule update --init
make start-deployment-btc-staking-integration-bitcoind-demo
```

This command will:

- Stop any existing deployment.
- Build all necessary components (babylond, bitcoindsim, vigilante, btc-staker,
    finality-provider, covenant-emulator, and ibcsim-bcd).
- Run the pre-deployment setup.
- Start the Docker containers.
- Run the post-deployment setup.
- Run the demo script that showcases all the user stories.

### Stop the deployment

```shell
make stop-deployment-btc-staking-integration-bitcoind
git submodule deinit
```

This will stop and remove the Docker containers, and clean up the test network
data.
It will also de-initialise / remove the submodules.
