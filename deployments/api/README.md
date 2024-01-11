# Babylon-API

## Components

This deployment features the Babylon API stack, which is connected to a pre-existing Babylon devnet, along with its BTC backend. It comprises the following components:

- **Babylon API**: Acts as a data aggregator for the Babylon network
- **RPC Poller**: Polls Babylon RPC endpoints and the network's BTC backend and stores data in a DB
- **Mongo DB**: Babylon data store

### Expected Docker state

The following containers should be created as a result of the `make` command
that spins up the network:

```shell
[+] Running 4/4
 ✔ Network artifacts_localnet    Created               0.1s
 ✔ Container mongodb           Started                0.5s
 ✔ Container rpc-poller        Started                0.8s
 ✔ Container babylon-api       Started                1.1s
```
