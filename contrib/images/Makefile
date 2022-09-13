all: bitcoinsim

bitcoinsim:
	docker build --tag babylonchain/bitcoinsim -f bitcoinsim/Dockerfile \
		$(shell git rev-parse --show-toplevel)/contrib/images/bitcoinsim

bitcoinsim-rmi:
	docker rmi babylonchain/bitcoinsim 2>/dev/null; true

.PHONY: all bitcoinsim bitcoinsim-rmi
