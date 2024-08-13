include .env
# Define GOPATH
export GOPATH := $(HOME)/go
# Add Foundry the PATH
export PATH := $(HOME)/.just:$(HOME)/.foundry/bin:$(GOPATH)/bin:$(PATH)
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

start-op-devnet:
	@./prepare-op-devnet.sh $(GIT_TOPLEVEL)/optimism
	@$(MAKE) -C $(GIT_TOPLEVEL)/optimism devnet-up
	sleep 10
	@./verify-op-devnet.sh
.PHONY: start-op-devnet

stop-op-devnet:
	@$(MAKE) -C $(GIT_TOPLEVEL)/optimism devnet-down
	@$(MAKE) -C $(GIT_TOPLEVEL)/optimism devnet-clean
.PHONY: stop-op-devnet

start: stop build
	@./init-testnets-dir.sh
	@$(DOCKER) compose -f artifacts/docker-compose.yml up -d
	sleep 10
	@./init-babylon-accounts.sh
	@./register-babylon-fp.sh
	@$(MAKE) start-op-devnet
	@./deploy-cw-contract.sh
	@$(DOCKER) compose -f artifacts/docker-compose-op-fp.yml up -d consumer-eotsmanager consumer-finality-provider
	sleep 5
	@./register-op-consumer.sh
	@./register-op-consumer-fp.sh
.PHONY: start

stop: stop-op-devnet
	@$(DOCKER) compose -f artifacts/docker-compose-op-fp.yml down
	@$(DOCKER) compose -f artifacts/docker-compose.yml down
	@rm -rf $(CURDIR)/.testnets
.PHONY: stop

demo-test:

# TODO: add .PHONY
