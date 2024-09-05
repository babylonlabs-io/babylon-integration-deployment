include .env
# Define GOPATH
export GOPATH := $(HOME)/go
# Add Foundry the PATH
export PATH := $(HOME)/.just:$(HOME)/.foundry/bin:/usr/local/go/bin:$(GOPATH)/bin:$(PATH)
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

build-finality-gadget:
	@$(MAKE) -C $(GIT_TOPLEVEL)/finality-gadget build-docker

build-cw-contract:
	@./build-cw-contract.sh $(GIT_TOPLEVEL)/babylon-contract

build: build-babylond \
	build-bitcoindsim \
	build-vigilante \
	build-btc-staker-phase-3 \
	build-finality-provider-phase-3 \
	build-finality-gadget \
	build-covenant-emulator \
	build-cw-contract

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
	@./deploy-cw-contract.sh $(GIT_TOPLEVEL)/babylon-contract
	@$(DOCKER) compose -f artifacts/docker-compose-fg.yml up -d \
		finality-gadget
	sleep 5
	@$(MAKE) start-op-devnet
	@$(DOCKER) compose -f artifacts/docker-compose-op-fp.yml up -d \
		consumer-eotsmanager \
		consumer-finality-provider
	sleep 10
	@./register-op-consumer.sh
	@./register-op-consumer-fp.sh
	@if [ -z "$(BITCOIN_NETWORK)" ] || [ "$(BITCOIN_NETWORK)" = "regtest" ]; then \
		echo "Creating BTC delegations for regtest..."; \
		./create-btc-delegations.sh; \
	elif [ "$(BITCOIN_NETWORK)" = "signet" ]; then \
		echo "Please wait until the local Bitcoin node is fully synced with the signet network."; \
		echo "Note: syncing can take several hours to complete."; \
		echo "To check if the Bitcoin node is synced, run the following command:"; \
		echo ". $(CURDIR)/verify-bitcoin-sync-balance.sh"; \
		echo "Once synced and has at least 0.01 BTC, to create BTC delegations by running the following command:"; \
		echo ". $(CURDIR)/create-btc-delegations.sh"; \
	fi
.PHONY: start

stop: stop-op-devnet
	@$(DOCKER) compose -f artifacts/docker-compose-op-fp.yml down
	@$(DOCKER) compose -f artifacts/docker-compose-fg.yml down
	@$(DOCKER) compose -f artifacts/docker-compose.yml down
	@rm -rf $(CURDIR)/.testnets
.PHONY: stop

demo-test:
	@./verify-babylon-finality.sh $(GIT_TOPLEVEL)/finality-gadget
.PHONY: demo-test