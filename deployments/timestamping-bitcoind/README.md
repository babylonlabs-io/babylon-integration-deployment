# BTC Timestamping deployment (BTC backend: bitcoind)

## Components

The to-be-deployed Babylon network that features Babylon's BTC Timestamping
protocol comprises the following components:

- 2 **Babylon Validator Nodes** running the base Tendermint consensus and producing
  Tendermint-confirmed Babylon blocks
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
[+] Running 7/7
 ✔ Network artifacts_localnet     Created                                                               0.1s 
 ✔ Container bitcoindsim          Started                                                               0.3s 
 ✔ Container babylondnode0        Started                                                               0.5s 
 ✔ Container babylondnode1        Started                                                               0.5s 
 ✔ Container vigilante-submitter  Started                                                               0.8s 
 ✔ Container vigilante-reporter   Started                                                               1.0s 
 ✔ Container vigilante-monitor    Started                                                               1.0s 
```
