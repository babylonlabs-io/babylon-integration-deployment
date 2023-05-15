all: bitcoinsim

btcdsim:
	docker build --tag babylonchain/btcdsim -f btcdsim/Dockerfile \
		$(shell git rev-parse --show-toplevel)/contrib/images/btcdsim

bitcoindsim:
	docker build --platform "linux/amd64" --tag babylonchain/bitcoindsim -f bitcoindsim/Dockerfile \
		$(shell git rev-parse --show-toplevel)/contrib/images/bitcoindsim

ibcsim-gaia:
	docker build --tag babylonchain/ibcsim-gaia -f ibcsim-gaia/Dockerfile \
		$(shell git rev-parse --show-toplevel)/contrib/images/ibcsim-gaia

btcdsim-rmi:
	docker rmi babylonchain/btcdsim 2>/dev/null; true

bitcoindsim-rmi:
	docker rmi babylonchain/bitcoindsim 2>/dev/null; true

ibcsim-gaia-rmi:
	docker rmi babylonchain/ibcsim-gaia 2>/dev/null; true

.PHONY: all btcdsim btcdsim-rmi bitcoindsim bitcoindsim-rmi ibcsim-gaia ibcsim-gaia-rmi
