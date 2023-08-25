DOCKER := $(shell which docker)
GIT_TOPLEVEL := $(shell git rev-parse --show-toplevel)

build-bitcoindsim:
	$(MAKE) -C $(GIT_TOPLEVEL)/contrib/images bitcoindsim

build-babylond:
	$(MAKE) -C $(GIT_TOPLEVEL)/babylon-private/contrib/images babylond

build-vigilante:
	$(MAKE) -C $(GIT_TOPLEVEL)/vigilante-private BBN_PRIV_DEPLOY_KEY=${BBN_PRIV_DEPLOY_KEY} build-docker

build-btc-staker:
	$(MAKE) -C $(GIT_TOPLEVEL)/btc-staker BBN_PRIV_DEPLOY_KEY=${BBN_PRIV_DEPLOY_KEY} build-docker

build-btc-validator:
	$(MAKE) -C $(GIT_TOPLEVEL)/btc-validator BBN_PRIV_DEPLOY_KEY=${BBN_PRIV_DEPLOY_KEY} build-docker

build-deployment-btcstaking-bitcoind: build-babylond build-bitcoindsim build-vigilante build-btc-staker build-btc-validator

start-deployment-btcstaking-bitcoind: stop-deployment-btcstaking-bitcoind build-deployment-btcstaking-bitcoind
	./pre-deployment.sh
	docker compose -f artifacts/docker-compose.yml up -d
	./post-deployment.sh

start-deployment-btcstaking-bitcoind-demo: start-deployment-btcstaking-bitcoind
	./btcstaking-demo.sh

stop-deployment-btcstaking-bitcoind:
	docker compose -f artifacts/docker-compose.yml down
	rm -rf $(CURDIR)/.testnets
