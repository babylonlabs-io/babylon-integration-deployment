## Babylon local deployment

This repository hosts a local deployment of the entire Babylon stack for
testing purposes. It involves:
- 2 validator nodes
- 1 vigilante submitter
- 1 vigilante reporter
- 1 vigilante monitor
- 1 bitcoin instance (currently btcd, in the future there is going to be
  support for bitcoind)
- 1 [gaiad](https://github.com/cosmos/gaia) instance connected to the validator
  node throuth an IBC [relayer](https://github.com/cosmos/relayer).

### Prerequisites

- Docker

### Dependencies

- [Babylon v0.6.0](https://github.com/babylonchain/babylon/tree/v0.6.0).
- [Vigilante version v0.6.0-rc0](https://github.com/babylonchain/vigilante/tree/v0.6.0-rc0).
- [Faucet commit 84e4c122d42a3b098bc92d8b8bf5e8bb596129e7](https://github.com/babylonchain/faucet/tree/84e4c122d42a3b098bc92d8b8bf5e8bb596129e7).
  This will be updated to a stable version when there is one for the faucet.

### Deploying

1. Retrieve the underlying repositories for Babylon, vigilante, and explorer:
```shell
git submodule init && git submodule update
```
2. Deploy the system
```shell
make start-deployment-btcd
```

*There is also the possibility to deploy the system along with a
Prometheus/Grafana monitoring stack (Grafana UI under port `3000`)*:
```shell
make start-monitored-deployment-btcd
```
3. Stop the system
```shell
make stop-deployment-btcd
```
4. Deploy the faucet (the faucet frontend under port `3000` and the backend under port `3001`)
```shell
make start-deployment-faucet
```
5. Stop the faucet
```shell
make stop-deployment-faucet
```

### System parameters

The Babylon nodes are deployed with the following parameters:
- 2 validators
- `chain-test` as the chain ID
- `bbt0` as the checkpoint tags
- 10 blocks epoch interval
- Validators are accessible through the `192.168.10.[2-5]` IP addresses.
- The explorer is accessible at port `localhost:26661`. This can be changed by
  modifying `LISTPORT` on the `docker-compose.yml` file.
- Bitcoin uses a block generation time of 30 seconds. This can be changed by
  adding an environment variable `GENERATE_INTERVAL_SECS` on the
  `docker-compose.yml` file.


The explorer is accessible at `localhost:26661`.

### Configuration files

The corresponding node directories, Bitcoin configuration, and
vigilante configuration can be found under `.testnets`
```console
$ ls .testnets
gentxs node0 node1 vigilante bitcoin
```

### Testing

To test a new feature in any of the dependent repositories:
1. Push your branch into the respective repository
2. Change to the directory of the repository maintained by this repository and
   change the branch to the one that contains your new changes.
3. Deploy the system and check that everything works properly.

#### Testing without commiting
For local development without pushing commits,
one can create the Docker image corresponding to the service that they're
testing, with the following names:
- `babylonchain/babylond` for Babylon nodes
- `babylonchain/vigilante` for the vigilante
- `babylonchain/explorer` for the explorer
- `babylonchain/nginx-proxy` for the explorer
- `babylonchain/faucet` for the faucet

#### Logs

In order to view the logs of a particular service, one can execute the command
```
docker logs <service_name>
```

This deployment uses the following service names:
- `babylondnode[0-3]` for the Babylon nodes
- `vigilante-reporter` for the reporter
- `vigilante-submitter` for the submitter
- `btcdsim` for the btcd service
- `explorer` for the explorer
- `nginx-proxy` for the nginx proxy
- `faucet-frontend` for the frontend of the faucet
- `faucet-backend` for the backend of the faucet

#### Sanity checks

Here are some checks that one can use to quickly verify if some basic things
are working properly (by viewing the explorer):
- On the first minutes, at least 100 blocks get reported
- Checkpoints become sealed
- Sealed checkpoints become submitted relativelly quickly when new Bitcoin
  blocks get generated
- Checkpoints become confirmed and finalized

If something goes wrong, viewing the logs for services can help. 
