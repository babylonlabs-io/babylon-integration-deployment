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

- [Babylon v0.7.2](https://github.com/babylonchain/babylon/tree/v0.7.2).
- [Vigilante version v0.7.0](https://github.com/babylonchain/vigilante/tree/v0.7.0).
- [Faucet v0.2.0](https://github.com/babylonchain/faucet/tree/v0.2.0).
  This will be updated to a stable version when there is one for the faucet.

### Deploying

1. Retrieve the underlying repositories for Babylon, vigilante, and faucet:
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
- Bitcoin uses a block generation time of 30 seconds. This can be changed by
  adding an environment variable `GENERATE_INTERVAL_SECS` on the
  `docker-compose.yml` file.


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
- `faucet-frontend` for the frontend of the faucet
- `faucet-backend` for the backend of the faucet

### BTC Staking

1. Retrieve a babylon-private deployment key and store it in a file
2. Run `make BBN_PRIV_DEPLOY_KEY="$DEPLOY_KEY_LOCATION" build-docker`

If there is any issue with building Docker images, you can go to the relevant
repos and build the Docker image manually with the appropriate name (using `make build-docker` commands)
and then remove the `build-<name>` part from the Makefile so that your manually
built docker image is used.
