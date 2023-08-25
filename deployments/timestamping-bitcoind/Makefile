DOCKER := $(shell which docker)
GIT_TOPLEVEL := $(shell git rev-parse --show-toplevel)

build-bitcoindsim:
	$(MAKE) -C $(GIT_TOPLEVEL)/contrib/images bitcoindsim

build-babylond:
	$(MAKE) -C $(GIT_TOPLEVEL)/babylon-private/contrib/images babylond

build-vigilante:
	$(MAKE) -C $(GIT_TOPLEVEL)/vigilante-private BBN_PRIV_DEPLOY_KEY=${BBN_PRIV_DEPLOY_KEY} build-docker

build-deployment-timestamping-bitcoind: build-babylond build-bitcoindsim build-vigilante

start-deployment-timestamping-bitcoind: stop-deployment-timestamping-bitcoind build-deployment-timestamping-bitcoind
	./pre-deployment.sh
	docker compose -f artifacts/docker-compose.yml up -d
	./post-deployment.sh

stop-deployment-timestamping-bitcoind:
	docker compose -f artifacts/docker-compose.yml down
	rm -rf $(CURDIR)/.testnets
