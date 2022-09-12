## Babylon local deployment

1. Build the Babylon Docker image. From the `babylon` directory:
```console
$ git clone github.com/babylonchain/babylon
$ cd babylon
$ make localnet-build-env
```
3. Build the vigilante submitter and reporter images:
```console
$ git clone github.com/babylonchain/vigilante
$ cd vigilante
$ make GITHUBUSER="your_github_username" GITHUBTOKEN="your_github_access_token" reporter-build
$ make GITHUBUSER="your_github_username" GITHUBTOKEN="your_github_access_token" submitter-build
```
4. Build the explorer and nginx proxy images:
```console
$ git clone github.com/babylonchain/babylon-explorer
$ cd babylon-explorer
$ make localnet-build-explorer
$ make localnet-build-nginx-proxy
```
5. Deploy the system
```console
$ make start-deployment
```

This will lead to the generation of a testnet with:
- 4 Babylon nodes
- 1 vigilante submitter
- 1 vigilante reporter
- 1 Bitcoin node running in simnet mode
- 1 Babylon explorer

The corresponding node directories, Bitcoin configuration, and
vigilante configuration can be found under `.testnets`
```console
$ ls .testnets
gentxs node0 node1 node2 node3 vigilante bitcoin
```

The explorer is accessible at `localhost:26661`.

