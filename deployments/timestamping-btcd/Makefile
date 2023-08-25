DOCKER := $(shell which docker)
GIT_TOPLEVEL := $(shell git rev-parse --show-toplevel)

build-btcdsim:
	$(MAKE) -C $(GIT_TOPLEVEL)/contrib/images btcdsim

build-babylond:
	$(MAKE) -C $(GIT_TOPLEVEL)/babylon-private/contrib/images babylond

build-vigilante:
	$(MAKE) -C $(GIT_TOPLEVEL)/vigilante-private BBN_PRIV_DEPLOY_KEY=${BBN_PRIV_DEPLOY_KEY} build-docker

build-deployment-timestamping-btcd: build-babylond build-btcdsim build-vigilante

start-deployment-timestamping-btcd: stop-deployment-timestamping-btcd build-deployment-timestamping-btcd
	./pre-deployment.sh
	docker compose -f artifacts/docker-compose.yml up -d
	./post-deployment.sh

stop-deployment-timestamping-btcd:
	docker compose -f artifacts/docker-compose.yml down
	rm -rf $(CURDIR)/.testnets
