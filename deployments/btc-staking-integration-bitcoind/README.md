# BTC staking integration deployment

This deployment scenario demonstrates the integration of Babylon network with
BTC Staking and a consumer chain, using a bitcoind private regtest network.
It showcases how the consumer chain integrates with Babylon for BTC staking.

## Components

1. **Babylon Network**: Two nodes of a private Babylon network.
2. **BTC Regression Testnet**: A local Bitcoin testnet using bitcoind for
   testing and development.
3. **Babylon Finality Provider**: A finality provider on the Babylon chain.
4. **BTC Staker**: A BTC staker that restakes to the Babylon and consumer
   finality provider.
5. **Consumer Chain**: A chain that is integrated with Babylon for BTC staking.
6. **Babylon Contracts**: Smart contracts on the consumer chain.
7. **Consumer chain finality provider**: A finality provider on the consumer
   chain.

## User stories covered

1. A consumer chain creates an IBC channel with the Babylon chain to start the
   integration.
2. A Babylon finality provider registers to the Babylon chain.
3. A consumer finality provider registers to the consumer chain.
4. A BTC staker restakes BTC to the Babylon and consumer finality providers.
5. The consumer finality provider commits public randomness and submits finality
   signatures to the consumer chain.
6. Blocks of the consumer chain are finalised by BTC staking.

## Usage

### Start the BTC staking integration demo

```shell
make start-deployment-btc-staking-integration-bitcoind-demo
```

This command will:

- Stop any existing deployment
- Build all necessary components (babylond, bitcoindsim, vigilante, btc-staker,
    finality-provider, covenant-emulator, and ibcsim-bcd)
- Run pre-deployment setup
- Start the Docker containers
- Run post-deployment setup
- Run the demo script that showcases all user stories

### Stop the deployment

```shell
make stop-deployment-btc-staking-integration-bitcoind
```

This will stop and remove the Docker containers and clean up the test network
data.
