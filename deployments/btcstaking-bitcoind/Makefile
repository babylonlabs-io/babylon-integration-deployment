DOCKER := $(shell which docker)
GIT_TOPLEVEL := $(shell git rev-parse --show-toplevel)

build-bitcoindsim:
	$(MAKE) -C $(GIT_TOPLEVEL)/contrib/images bitcoindsim

build-babylond:
	$(MAKE) -C $(GIT_TOPLEVEL)/babylon-private/contrib/images babylond

build-vigilante:
	$(MAKE) -C $(GIT_TOPLEVEL)/vigilante-private build-docker

build-btc-staker:
	$(MAKE) -C $(GIT_TOPLEVEL)/btc-staker build-docker

build-finality-provider:
	$(MAKE) -C $(GIT_TOPLEVEL)/finality-provider build-docker

build-covenant-emulator:
	$(MAKE) -C $(GIT_TOPLEVEL)/covenant-emulator build-docker

build-poller:
	$(MAKE) -C $(GIT_TOPLEVEL)/rpc-poller build-docker

build-api:
	$(MAKE) -C $(GIT_TOPLEVEL)/babylon-api build-docker

build-deployment-btcstaking-bitcoind: build-babylond build-bitcoindsim build-vigilante build-btc-staker build-finality-provider build-covenant-emulator build-poller build-api

start-deployment-btcstaking-bitcoind: stop-deployment-btcstaking-bitcoind build-deployment-btcstaking-bitcoind
	./pre-deployment.sh
	docker compose -f artifacts/docker-compose.yml up -d
	./post-deployment.sh

start-deployment-btcstaking-bitcoind-demo: start-deployment-btcstaking-bitcoind
	./btcstaking-demo.sh

stop-deployment-btcstaking-bitcoind:
	docker compose -f artifacts/docker-compose.yml down
	rm -rf $(CURDIR)/.testnets
