# BTC Discord Faucet deployment

## Components

The to-be-deployed Babylon network that tests a bitcoin node's integration with a
Discord-based Faucet comprises the following components:

- **Bitcoind Node Emulator** running on the bitcoin regtest.
- **Faucet** daemon that listens to a Discord channel, gets Bitcoin token requests
  for specific Bitcoin addresses from Discord users and executes the
  corresponding Bitcoin transactions

### Expected Docker state post-deployment

The following containers should be created as a result of the `make` command
that spins up the network:

```shell
[+] Running 3/3
✔ Network artifacts_localnet  Created                                                                  0.1s 
 ✔ Container bitcoindsim       Started                                                                  0.5s 
 ✔ Container faucet-backend    Started                                                                  0.7s 
```
