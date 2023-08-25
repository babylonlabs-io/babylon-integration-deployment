# Phase 1 Integration deployment (BTC backend: bitcoind)

## Components

The to-be-deployed Babylon network that tests Babylon's **Phase 1 Integration**
with a gaiad testnet comprises the following components:

- 2 **Babylon Validator Nodes** running the base Tendermint consensus and producing
  Tendermint-confirmed Babylon blocks
- **gaiad** testnet: An IBC light client towards this client chain is created and
  committed on Babylon; then, blocks of the client chain get periodically
  included in Babylon blocks and subsequently receive BTC timestamps
  through Babylon (this constitutes a **Phase 1 Integration** with Babylon)
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
 ✔ Container ibcsim-gaia          Started                                                          0.9s 
 ✔ Container vigilante-monitor    Started                                                          1.1s 
 ✔ Container vigilante-reporter   Started                                                          1.1s 
 ✔ Container vigilante-submitter  Started                                                          1.1s
```
