all: bitcoinsim

btcdsim:
	docker build --tag babylonchain/btcdsim -f btcdsim/Dockerfile \
		$(shell git rev-parse --show-toplevel)/contrib/images/btcdsim

bitcoindsim:
	docker build --tag babylonchain/bitcoindsim -f bitcoindsim/Dockerfile \
		$(shell git rev-parse --show-toplevel)/contrib/images/bitcoind

btcdsim-rmi:
	docker rmi babylonchain/btcdsim 2>/dev/null; true

.PHONY: all btcdsim btcdsim-rmi
