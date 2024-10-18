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
	@$(MAKE) -C $(GIT_TOPLEVEL)/babylon/contrib/images babylond

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

build: build-babylond \
	build-bitcoindsim \
	build-vigilante \
	build-btc-staker-phase-3 \
	build-finality-provider-phase-3 \
	build-finality-gadget \
	build-covenant-emulator

# ## Start the OP chain on the local L1 chain
# start-op-devnet:
# 	@$(CURDIR)/optimism/install-deps.sh $(GIT_TOPLEVEL)/optimism
# 	@$(MAKE) -C $(GIT_TOPLEVEL)/optimism devnet-up
# 	sleep 10
#     ## true represent the OP chain is deployed on the local L1 chain
# 	@$(CURDIR)/optimism/verify-op-devnet.sh true
# .PHONY: start-op-devnet

# ## Stop the OP chain on the local L1 chain
# stop-op-devnet:
# 	@$(MAKE) -C $(GIT_TOPLEVEL)/optimism devnet-down
# 	@$(MAKE) -C $(GIT_TOPLEVEL)/optimism devnet-clean
# .PHONY: stop-op-devnet

# start: stop build
# 	@./init-testnets-dir.sh
# 	@$(DOCKER) compose -f artifacts/docker-compose.yml up -d
# 	sleep 10
# 	@./init-babylon-accounts.sh
# 	@./register-babylon-fp.sh
# 	@./deploy-cw-contract.sh $(CURDIR)/artifacts/op_finality_gadget-v0.10.0-rc.0.wasm
# 	@$(DOCKER) compose -f artifacts/docker-compose-fg.yml up -d \
# 		finality-gadget
# 	sleep 5
# 	@$(MAKE) start-op-devnet
# 	@$(DOCKER) compose -f artifacts/docker-compose-op-fp.yml up -d \
# 		consumer-eotsmanager \
# 		consumer-finality-provider
# 	sleep 10
# 	@./register-op-consumer.sh
# 	@./register-op-consumer-fp.sh
# 	@if [ -z "$(BITCOIN_NETWORK)" ] || [ "$(BITCOIN_NETWORK)" = "regtest" ]; then \
# 		echo "Creating BTC delegations for regtest..."; \
# 		./create-btc-delegations.sh; \
# 	elif [ "$(BITCOIN_NETWORK)" = "signet" ] || [ "$(BITCOIN_NETWORK)" = "testnet" ]; then \
# 		echo "Please wait until the local Bitcoin node is fully synced with the signet network."; \
# 		echo "Note: syncing can take several hours to complete."; \
# 		echo "To check if the Bitcoin node is synced, run the following command:"; \
# 		echo "cd $(CURDIR) && ./verify-bitcoin-sync-balance.sh"; \
# 		echo "Once synced and has at least 0.01 BTC, to create BTC delegations by running the following command:"; \
# 		echo "cd $(CURDIR) && ./create-btc-delegations.sh"; \
# 	else \
# 		echo "Unsupported bitcoin network: $(BITCOIN_NETWORK)"; \
# 	fi
# .PHONY: start

# stop: stop-op-devnet
# 	@$(DOCKER) compose -f artifacts/docker-compose-op-fp.yml down
# 	@$(DOCKER) compose -f artifacts/docker-compose-fg.yml down
# 	@$(DOCKER) compose -f artifacts/docker-compose.yml down
# 	@rm -rf $(CURDIR)/.testnets
# 	@if [ -z "$(BITCOIN_NETWORK)" ] || [ "$(BITCOIN_NETWORK)" = "regtest" ]; then \
# 		echo "Removing Bitcoin data for regtest..."; \
# 		rm -rf $(CURDIR)/.bitcoin; \
# 	elif [ "$(BITCOIN_NETWORK)" = "signet" ] || [ "$(BITCOIN_NETWORK)" = "testnet" ]; then \
# 		echo "Keeping Bitcoin data for $(BITCOIN_NETWORK) to preserve sync state..."; \
# 		echo "To remove Bitcoin data for $(BITCOIN_NETWORK), if no longer needed, run the following command:"; \
# 		echo "rm -rf $(CURDIR)/.bitcoin"; \
# 	else \
# 		echo "Unsupported bitcoin network: $(BITCOIN_NETWORK)"; \
# 	fi
# .PHONY: stop

demo-test:
	@./verify-babylon-finality.sh $(GIT_TOPLEVEL)/finality-gadget
.PHONY: demo-test


# ## Start the local L1 chain
# start-local-l1-chain:
# 	@$(MAKE) -C $(GIT_TOPLEVEL)/optimism pre-devnet
# 	$(eval include $(CURDIR)/optimism/.env)
# 	@$(CURDIR)/optimism/start-local-l1-chain.sh $(GIT_TOPLEVEL)/optimism $(CURDIR)/optimism
# .PHONY: start-local-l1-chain

# ## Stop the local L1 chain
# stop-local-l1-chain:
# 	@rm -rf $(GIT_TOPLEVEL)/optimism/packages/contracts-bedrock/deployments/devnetL1
# 	@rm -rf $(GIT_TOPLEVEL)/optimism/.devnet
# 	@$(DOCKER) compose -f $(GIT_TOPLEVEL)/optimism/ops-bedrock/docker-compose.yml down l1 l1-bn l1-vc
# 	@$(DOCKER) image ls 'ops-bedrock*' --format='{{.Repository}}' | xargs -r docker rmi
# 	@$(DOCKER) volume ls --filter name=ops-bedrock --format='{{.Name}}' | xargs -r docker volume rm
# .PHONY: stop-local-l1-chain
# ## Prepare for running the OP chain on the Sepolia testnet
# prepare-op-chain:
# 	@$(eval export IMPL_SALT := $(shell openssl rand -hex 32))
# 	@$(CURDIR)/optimism/install-deps.sh $(GIT_TOPLEVEL)/optimism
# 	$(eval include $(CURDIR)/optimism/.env)
# 	@$(CURDIR)/optimism/generate-deploy-config.sh $(GIT_TOPLEVEL)/optimism
# 	@$(CURDIR)/optimism/deploy-l1-contracts.sh $(GIT_TOPLEVEL)/optimism
# 	@$(CURDIR)/optimism/generate-l2-config.sh $(GIT_TOPLEVEL)/optimism $(CURDIR)/optimism
# .PHONY: prepare-op-chain

# ## Common logic for starting/restarting OP chain on Sepolia
# _launch-op-chain-sepolia:
# 	@$(CURDIR)/optimism/launch-l2.sh $(GIT_TOPLEVEL)/optimism $(CURDIR)/optimism
# 	sleep 10
# 	## false represents the OP chain is deployed on the Sepolia testnet, not local L1
# 	@$(CURDIR)/optimism/verify-op-devnet.sh false

# ## Start the OP chain on the Sepolia testnet
# start-op-chain-sepolia: prepare-op-chain _launch-op-chain-sepolia
# .PHONY: start-op-chain-sepolia

# ## Restart the OP chain on the Sepolia testnet
# restart-op-chain-sepolia:
# 	@$(eval include $(CURDIR)/optimism/.env)
# 	@$(MAKE) _launch-op-chain-sepolia
# .PHONY: restart-op-chain-sepolia

# ## Stop the OP chain on the Sepolia testnet
# stop-op-chain-sepolia:
# 	@$(DOCKER) compose -f $(CURDIR)/optimism/docker-compose.yml down
# 	@rm -rf $(CURDIR)/optimism/.deploy
# 	$(eval include $(CURDIR)/optimism/.env)
# 	@rm -f $(GIT_TOPLEVEL)/optimism/packages/contracts-bedrock/deploy-config/sepolia-devnet-$(L2_CHAIN_ID).json
# 	@rm -f $(GIT_TOPLEVEL)/optimism/packages/contracts-bedrock/deployments/sepolia-devnet-$(L2_CHAIN_ID).json
# 	@$(DOCKER) volume ls --filter name=optimism --format='{{.Name}}' | xargs -r docker volume rm
# .PHONY: stop-op-chain-sepolia

start-babylon:
	@./init-testnets-dir.sh
	@$(DOCKER) compose -f artifacts/docker-compose.yml up -d
	sleep 10
	@./init-babylon-accounts.sh
	@./register-babylon-fp.sh
	@./deploy-cw-contract.sh $(CURDIR)/artifacts/op_finality_gadget-v0.10.0-rc.0.wasm
	@$(DOCKER) compose -f artifacts/docker-compose-fg.yml up -d \
		finality-gadget
	sleep 5
	@$(DOCKER) compose -f artifacts/docker-compose-op-fp.yml up -d \
		consumer-eotsmanager \
		consumer-finality-provider
	sleep 10
	@./register-op-consumer.sh
	@./register-op-consumer-fp.sh
	@if [ -z "$(BITCOIN_NETWORK)" ] || [ "$(BITCOIN_NETWORK)" = "regtest" ]; then \
		echo "Creating BTC delegations for regtest..."; \
		./create-btc-delegations.sh; \
	elif [ "$(BITCOIN_NETWORK)" = "signet" ] || [ "$(BITCOIN_NETWORK)" = "testnet" ]; then \
		echo "Please wait until the local Bitcoin node is fully synced with the signet network."; \
		echo "Note: syncing can take several hours to complete."; \
		echo "To check if the Bitcoin node is synced, run the following command:"; \
		echo "cd $(CURDIR) && ./verify-bitcoin-sync-balance.sh"; \
		echo "Once synced and has at least 0.01 BTC, to create BTC delegations by running the following command:"; \
		echo "cd $(CURDIR) && ./create-btc-delegations.sh"; \
	else \
		echo "Unsupported bitcoin network: $(BITCOIN_NETWORK)"; \
	fi
.PHONY: start

stop-babylon:
	@$(DOCKER) compose -f artifacts/docker-compose.yml down -v
	@$(DOCKER) compose -f artifacts/docker-compose-op-fp.yml down
	@$(DOCKER) compose -f artifacts/docker-compose-fg.yml down
	@sudo rm -rf $(CURDIR)/.testnets
	@if [ -z "$(BITCOIN_NETWORK)" ] || [ "$(BITCOIN_NETWORK)" = "regtest" ]; then \
		echo "Removing Bitcoin data for regtest..."; \
		sudo rm -rf $(CURDIR)/.bitcoin; \
	elif [ "$(BITCOIN_NETWORK)" = "signet" ] || [ "$(BITCOIN_NETWORK)" = "testnet" ]; then \
		echo "Keeping Bitcoin data for $(BITCOIN_NETWORK) to preserve sync state..."; \
		echo "To remove Bitcoin data for $(BITCOIN_NETWORK), if no longer needed, run the following command:"; \
		echo "rm -rf $(CURDIR)/.bitcoin"; \
	else \
		echo "Unsupported bitcoin network: $(BITCOIN_NETWORK)"; \
	fi
.PHONY: stop

# Run independent steps 
# TODO: remove these after testing

init-testnets-dir:
	@./init-testnets-dir.sh
.PHONY: init-testnets-dir

init-babylon-accounts:
	@./init-babylon-accounts.sh
.PHONY: init-babylon-accounts

register-babylon-fp:
	@./register-babylon-fp.sh
.PHONY: register-babylon-fp

deploy-cw-contract:
	@./deploy-cw-contract.sh $(GIT_TOPLEVEL)/babylon-contract
.PHONY: deploy-cw-contract

register-op-consumer:
	@./register-op-consumer.sh
.PHONY: register-op-consumer

register-op-consumer-fp:
	@./register-op-consumer-fp.sh
.PHONY: register-op-consumer-fp

create-btc-delegations:
	@./create-btc-delegations.sh
.PHONY: create-btc-delegations
