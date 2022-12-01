all: bitcoinsim

btcdsim:
	docker build --tag babylonchain/btcdsim -f btcdsim/Dockerfile \
		$(shell git rev-parse --show-toplevel)/contrib/images/btcdsim

bitcoindsim:
	docker build --tag babylonchain/bitcoindsim -f bitcoindsim/Dockerfile \
		$(shell git rev-parse --show-toplevel)/contrib/images/bitcoind

ibcsim:
	docker build --tag babylonchain/ibcsim -f ibcsim/Dockerfile \
		$(shell git rev-parse --show-toplevel)/contrib/images/ibcsim

btcdsim-rmi:
	docker rmi babylonchain/btcdsim 2>/dev/null; true

bitcoindsim-rmi:
	docker rmi babylonchain/bitcoindsim 2>/dev/null; true

ibcsim-rmi:
	docker rmi babylonchain/ibcsim 2>/dev/null; true

.PHONY: all btcdsim btcdsim-rmi bitcoindsim bitcoindsim-rmi ibcsim ibcsim-rmi
