ifeq ($(BITCOIN_CORE_VERSION),)
	BITCOINDSIM_TAG := latest
else
	BITCOINDSIM_BUILD_ARG := --build-arg BITCOIN_CORE_VERSION=$(BITCOIN_CORE_VERSION)
	BITCOINDSIM_TAG := $(BITCOIN_CORE_VERSION)
endif

all: bitcoinsim ibcsim-wasmd

bitcoindsim:
	docker build --platform "linux/amd64" --tag babylonlabs-io/bitcoindsim:$(BITCOINDSIM_TAG) -f bitcoindsim/Dockerfile \
		$(shell git rev-parse --show-toplevel)/contrib/images/bitcoindsim $(BITCOINDSIM_BUILD_ARG)

ibcsim-wasmd:
	cd ibcsim-wasmd/babylon-contract && \
	cargo install cargo-run-script && \
	cargo clean && \
	cargo build && \
	cargo run-script optimize 2>/dev/null; true

ibcsim-gaia:
	docker build --tag babylonlabs-io/ibcsim-gaia -f ibcsim-gaia/Dockerfile \
		$(shell git rev-parse --show-toplevel)/contrib/images/ibcsim-gaia

ibcsim-bcd:
	docker build --secret id=sshKey,src=${BBN_PRIV_DEPLOY_KEY} \
		--tag babylonlabs-io/ibcsim-bcd -f ibcsim-bcd/Dockerfile \
		$(shell git rev-parse --show-toplevel)/contrib/images/ibcsim-bcd

ibcsim-wasmd-clean:
	cd ibcsim-wasmd/babylon-contract && rm -rf artifacts 2>/dev/null; true

btcdsim-rmi:
	docker rmi babylonlabs-io/btcdsim 2>/dev/null; true

bitcoindsim-rmi:
	docker rmi babylonlabs-io/bitcoindsim 2>/dev/null; true

ibcsim-gaia-rmi:
	docker rmi babylonlabs-io/ibcsim-gaia 2>/dev/null; true

ibcsim-bcd-rmi:
	docker rmi babylonlabs-io/ibcsim-bcd 2>/dev/null; true

.PHONY: all btcdsim ibcsim-wasmd ibcsim-wasmd-clean btcdsim-rmi bitcoindsim bitcoindsim-rmi ibcsim-gaia ibcsim-gaia-rmi ibcsim-bcd ibcsim-bcd-rmi
