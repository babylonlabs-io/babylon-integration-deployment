# Faucet deployment

## Components

The to-be-deployed Babylon network that tests Babylon's integration with a
Discord-based Faucet comprises the following components:

- 2 **Babylon Validator Nodes** running the base Tendermint consensus and producing
  Tendermint-confirmed Babylon blocks
- **Faucet** daemon that listens to a Discord channel, gets Babylon token requests
  for specific Babylon addresses from Discord users and executes the
  corresponding Babylon transactions

### Expected Docker state post-deployment

The following containers should be created as a result of the `make` command
that spins up the network:

```shell
[+] Running 4/4
✔ Network artifacts_localnet  Created                                                                  0.1s 
 ✔ Container babylondnode1     Started                                                                  0.5s 
 ✔ Container babylondnode0     Started                                                                  0.5s 
 ✔ Container faucet-backend    Started                                                                  0.7s 
```
