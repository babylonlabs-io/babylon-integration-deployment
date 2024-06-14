# Phase 2 Integration deployment (BTC backend: bitcoind)

## Components

The to-be-deployed Babylon network that tests Babylon's **Phase 2 Integration**
with a gaiad testnet comprises the following components:

- 2 **Babylon Validator Nodes** running the base Tendermint consensus and producing
  Tendermint-confirmed Babylon blocks
- **wasmd** testnet: A Babylon wasmd smart contract which enables fast stake
  unbonding is deployed on the wasmd testnet; subsequently, an IBC channel is 
  set up between Babylon and wasmd by creating IBC clients on both chains, to
  activate the fast unbonding (this constitutes a **Phase 2 Integration** with
  Babylon)
- **Vigilante Monitor** daemon: Detects attacks to Babylon
- **Vigilante Submitter** daemon: Aggregates and checkpoints Babylon epochs (a
  group of `X` Babylon blocks) to the BTC network
- **Vigilante Reporter** daemon: Keeps track of the BTC network's state in
  Babylon and detects Babylon checkpoints that have received a BTC timestamp
  (i.e. have been confirmed in BTC)
- A **BTC simnet** acting as the BTC network, operated through a bitcoind node

### Expected Docker state post-deployment

The following containers should be created as a result of the `make` command
that spins up the network:

```shell
[+] Running 8/8
 ✔ Network artifacts_localnet     Created                                                          0.1s 
 ✔ Container bitcoindsim          Started                                                          0.6s 
 ✔ Container babylondnode1        Started                                                          0.5s 
 ✔ Container babylondnode0        Started                                                          0.4s 
 ✔ Container ibcsim-bcd           Started                                                          0.9s 
 ✔ Container vigilante-monitor    Started                                                          1.1s 
 ✔ Container vigilante-reporter   Started                                                          1.1s 
 ✔ Container vigilante-submitter  Started                                                          1.1s
```
