DOCKER := $(shell which docker)
GIT_TOPLEVEL := $(shell git rev-parse --show-toplevel)

build-bitcoindsim:
	$(MAKE) -C $(GIT_TOPLEVEL)/contrib/images bitcoindsim

build-ibcsim-wasmd:
	$(MAKE) -C $(GIT_TOPLEVEL)/contrib/images ibcsim-wasmd

build-babylond:
	$(MAKE) -C $(GIT_TOPLEVEL)/babylon-private/contrib/images babylond

build-vigilante:
	$(MAKE) -C $(GIT_TOPLEVEL)/vigilante-private BBN_PRIV_DEPLOY_KEY=${BBN_PRIV_DEPLOY_KEY} build-docker

build-deployment-phase2-integration-bitcoind: build-babylond build-bitcoindsim build-vigilante build-ibcsim-wasmd

start-deployment-phase2-integration-bitcoind: stop-deployment-phase2-integration-bitcoind build-deployment-phase2-integration-bitcoind
	./pre-deployment.sh
	docker compose -f artifacts/docker-compose.yml up -d
	./post-deployment.sh

stop-deployment-phase2-integration-bitcoind:
	docker compose -f artifacts/docker-compose.yml down
	rm -rf $(CURDIR)/.testnets
