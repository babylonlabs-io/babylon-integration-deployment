all: bitcoinsim

btcdsim:
	docker build --tag babylonchain/btcdsim -f btcdsim/Dockerfile \
		$(shell git rev-parse --show-toplevel)/contrib/images/btcdsim

btcdsim-rmi:
	docker rmi babylonchain/btcdsim 2>/dev/null; true

.PHONY: all btcdsim btcdsim-rmi
