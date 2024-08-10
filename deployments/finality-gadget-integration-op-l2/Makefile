include .env
export

DOCKER := $(shell which docker)
GIT_TOPLEVEL := $(shell git rev-parse --show-toplevel)

build-bitcoindsim:
	@$(MAKE) -C $(GIT_TOPLEVEL)/contrib/images bitcoindsim

build-babylond:
	@$(MAKE) -C $(GIT_TOPLEVEL)/babylon-private/contrib/images babylond

build-vigilante:
	@$(MAKE) -C $(GIT_TOPLEVEL)/vigilante build-docker

build-btc-staker-phase-3:
	@$(MAKE) -C $(GIT_TOPLEVEL)/btc-staker-phase-3 build-docker

build-finality-provider-phase-3:
	@$(MAKE) -C $(GIT_TOPLEVEL)/finality-provider-phase-3 build-docker

build-covenant-emulator:
	@$(MAKE) -C $(GIT_TOPLEVEL)/covenant-emulator build-docker

build: build-babylond \
	build-bitcoindsim \
	build-vigilante \
	build-btc-staker-phase-3 \
	build-finality-provider-phase-3

start-op-devnet: stop-op-devnet
	@./prepare-op-devnet.sh $(GIT_TOPLEVEL)/optimism
	@$(MAKE) -C $(GIT_TOPLEVEL)/optimism devnet-up

stop-op-devnet:
	@$(MAKE) -C $(GIT_TOPLEVEL)/optimism devnet-down
	@$(MAKE) -C $(GIT_TOPLEVEL)/optimism devnet-clean

start:stop build
	@./init-testnets-dir.sh
	@$(DOCKER) compose -f artifacts/docker-compose.yml up -d
	sleep 7
	@./init-babylon-accounts.sh
	@./deploy-cw-contract.sh
	@./register-op-consumer.sh
	@./register-babylon-fp.sh
#TODO: 1) register babylon FP; 2) register op FP; 3) btc deletation; 4) op system; 5) covenant setup

stop:
	@$(DOCKER) compose -f artifacts/docker-compose.yml down
	@rm -rf $(CURDIR)/.testnets
	echo

demo-test:

# TODO: add .PHONY
