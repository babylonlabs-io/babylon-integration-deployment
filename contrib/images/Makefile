ifeq ($(BITCOIN_CORE_VERSION),)
	BITCOINDSIM_TAG := latest
else
	BITCOINDSIM_BUILD_ARG := --build-arg BITCOIN_CORE_VERSION=$(BITCOIN_CORE_VERSION)
	BITCOINDSIM_TAG := $(BITCOIN_CORE_VERSION)
endif

all: bitcoinsim

bitcoindsim:
	docker build --platform "linux/amd64" --tag babylonchain/bitcoindsim:$(BITCOINDSIM_TAG) -f bitcoindsim/Dockerfile \
		$(shell git rev-parse --show-toplevel)/contrib/images/bitcoindsim $(BITCOINDSIM_BUILD_ARG)

ibcsim-gaia:
	docker build --tag babylonchain/ibcsim-gaia -f ibcsim-gaia/Dockerfile \
		$(shell git rev-parse --show-toplevel)/contrib/images/ibcsim-gaia

ibcsim-bcd:
	docker build --secret id=sshKey,src=${BBN_PRIV_DEPLOY_KEY} \
		--tag babylonchain/ibcsim-bcd -f ibcsim-bcd/Dockerfile \
		$(shell git rev-parse --show-toplevel)/contrib/images/ibcsim-bcd

btcdsim-rmi:
	docker rmi babylonchain/btcdsim 2>/dev/null; true

bitcoindsim-rmi:
	docker rmi babylonchain/bitcoindsim 2>/dev/null; true

ibcsim-gaia-rmi:
	docker rmi babylonchain/ibcsim-gaia 2>/dev/null; true

ibcsim-bcd-rmi:
	docker rmi babylonchain/ibcsim-bcd 2>/dev/null; true

.PHONY: all btcdsim btcdsim-rmi bitcoindsim bitcoindsim-rmi ibcsim-gaia ibcsim-gaia-rmi ibcsim-bcd ibcsim-bcd-rmi
