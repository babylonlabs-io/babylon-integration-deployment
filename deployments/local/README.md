# Local Deployment

## Requirements

- [btcd](https://github.com/btcsuite/btcd/tree/master?tab=readme-ov-file#installation) binaries (on your path)
- [jq](https://jqlang.github.io/jq/download/)
- [perl](https://www.perl.org/get.html)

## Start paths

### Phase-2 full test

Starts all the processes necessary to have a btc delegation active, stops the
chain process, export the genesis, setup a new chain with new chain id
copy some data from the exported genesis into the new one and start a new chain
with active btc delegations from start.

```shell
make start-phase-2-full-test
```

- Wait for the first bbn chain to get a active btc del

```shel
Current active dels: 0, waiting to reach 1
Current active dels: 0, waiting to reach 1
...
```

- When the first active btc del is reached, it kills the bbn chain, exports and starts new one
- You should see a second bbn chain start with active btc del

```shell
babylond q btcstaking btc-delegations active -o json | jq
```

### Single BBN Node with BTC delegation

Starts all the process necessary to have a babylon chain running with active btc delegation.

```shell
make start-bbn-with-btc-delegation
```

- Wait for about a minute and query

```shell
babylond q btcstaking btc-delegations active -o json | jq
```

- You should see a btc delegation active, if nothing is founded check pending btc delegations `babylond q btcstaking btc-delegations pending`

## Tear down

Kills all the process that were preivously started and deletes the data folder

```shell
make stop-all
```
