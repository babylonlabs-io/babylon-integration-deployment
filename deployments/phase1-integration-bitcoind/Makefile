DOCKER := $(shell which docker)
GIT_TOPLEVEL := $(shell git rev-parse --show-toplevel)

build-bitcoindsim:
	$(MAKE) -C $(GIT_TOPLEVEL)/contrib/images bitcoindsim

build-ibcsim-gaia:
	$(MAKE) -C $(GIT_TOPLEVEL)/contrib/images ibcsim-gaia

build-babylond:
	$(MAKE) -C $(GIT_TOPLEVEL)/babylon-private/contrib/images babylond

build-vigilante:
	$(MAKE) -C $(GIT_TOPLEVEL)/vigilante-private BBN_PRIV_DEPLOY_KEY=${BBN_PRIV_DEPLOY_KEY} build-docker

build-deployment-phase1-integration-bitcoind: build-babylond build-bitcoindsim build-vigilante build-ibcsim-gaia

start-deployment-phase1-integration-bitcoind: stop-deployment-phase1-integration-bitcoind build-deployment-phase1-integration-bitcoind
	./pre-deployment.sh
	docker compose -f artifacts/docker-compose.yml up -d
	./post-deployment.sh

stop-deployment-phase1-integration-bitcoind:
	docker compose -f artifacts/docker-compose.yml down
	rm -rf $(CURDIR)/.testnets
