include .env
export

DOCKER := $(shell which docker)
GIT_TOPLEVEL := $(shell git rev-parse --show-toplevel)

build-bitcoindsim:
	$(MAKE) -C $(GIT_TOPLEVEL)/contrib/images bitcoindsim

build-babylond:
	$(MAKE) -C $(GIT_TOPLEVEL)/babylon-private/contrib/images babylond

build-vigilante:
	$(MAKE) -C $(GIT_TOPLEVEL)/vigilante build-docker

build-btc-staker-phase-3:
	$(MAKE) -C $(GIT_TOPLEVEL)/btc-staker-phase-3 build-docker

build-finality-provider-phase-3:
	$(MAKE) -C $(GIT_TOPLEVEL)/finality-provider-phase-3 build-docker

build-covenant-emulator:
	$(MAKE) -C $(GIT_TOPLEVEL)/covenant-emulator build-docker

build-deployment-finality-gadget-integration-op-l2: build-babylond build-bitcoindsim build-vigilante

start-deployment-finality-gadget-integration-op-l2: stop-deployment-finality-gadget-integration-op-l2 build-deployment-finality-gadget-integration-op-l2
	@./pre-deployment.sh
	$(DOCKER) compose -f artifacts/docker-compose.yml up -d
	@./post-deployment.sh

stop-deployment-finality-gadget-integration-op-l2:
	$(DOCKER) compose -f artifacts/docker-compose.yml down
	rm -rf $(CURDIR)/.testnets

# Start demo
.PHONY: demo-start
demo-start: start-deployment-finality-gadget-integration-op-l2
	@./deploy-cw-contract.sh
	@./register-op-consumer.sh

.PHONY: demo-test
demo-test: demo-start
