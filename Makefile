DOCKER := $(shell which docker)

build-btcdsim:
	$(MAKE) -C contrib/images btcdsim

build-bitcoindsim:
	$(MAKE) -C contrib/images bitcoindsim

build-ibcsim:
	$(MAKE) -C contrib/images ibcsim

build-babylond:
	# Hack: Go does not like it when using git submodules
	# See: https://github.com/golang/go/issues/53640
	cd babylon; mv .git .git.bk; cp -R ../.git/modules/babylon .git; $(MAKE) localnet-build-env; rm -rf .git; mv .git.bk .git

build-vigilante-reporter:
	$(MAKE) -C vigilante reporter-build

build-vigilante-submitter:
	$(MAKE) -C vigilante submitter-build

build-explorer:
	$(MAKE) -C babylon-explorer localnet-build-explorer
	$(MAKE) -C babylon-explorer localnet-build-nginx-proxy

build-deployment-btcd: build-btcdsim build-ibcsim build-babylond build-vigilante-reporter build-vigilante-submitter build-explorer

build-deployment-bitcoind: build-bitcoindsim build-ibcsim build-babylond build-vigilante-reporter build-vigilante-submitter build-explorer

start-deployment-btcd: stop-deployment-btcd build-deployment-btcd
	$(DOCKER) run --rm -v $(CURDIR)/.testnets:/data babylonchain/babylond \
			  testnet init-files --v 2 -o /data \
			  --starting-ip-address 192.168.10.2 --keyring-backend=test \
			  --chain-id chain-test --btc-checkpoint-tag bbt0 --epoch-interval 10 \
			  --minimum-gas-prices 0.000006ubbn \
			  --btc-finalization-timeout 2 --btc-confirmation-depth 1
	# volume in which the bitcoin configuration will be mounted
	mkdir -p $(CURDIR)/.testnets/bitcoin
	# TODO: Once vigilante implements a testnet command we will use that one instead of
	#  		manually creating and copying the config file
	mkdir -p $(CURDIR)/.testnets/vigilante
	cp $(CURDIR)/vigilante-btcd.yml $(CURDIR)/.testnets/vigilante/vigilante.yml
	# Start the docker compose
	docker-compose -f btcdsim.docker-compose.yml up -d explorer vigilante-reporter vigilante-submitter ibcsim babylondnode0 babylondnode1 nginx-proxy btcdsim

start-monitored-deployment-btcd: start-deployment-btcd
	docker-compose -f btcdsim.docker-compose.yml up -d prometheus grafana

start-deployment-bitcoind: stop-deployment-bitcoind build-deployment-bitcoind
	$(DOCKER) run --rm -v $(CURDIR)/.testnets:/data babylonchain/babylond \
			  testnet init-files --v 2 -o /data \
			  --starting-ip-address 192.168.10.2 --keyring-backend=test \
			  --chain-id chain-test --btc-checkpoint-tag bbt0 --epoch-interval 10 \
			  --btc-finalization-timeout 2 --btc-confirmation-depth 1 \
			  --minimum-gas-prices 0.000006ubbn \
			  --btc-base-header 0100000000000000000000000000000000000000000000000000000000000000000000003ba3edfd7a7b12b27ac72c3e67768f617fc81bc3888a51323a9fb8aa4b1e5e4adae5494dffff7f2002000000 \
			  --btc-network regtest
	# volume in which the bitcoin configuration will be mounted
	mkdir -p $(CURDIR)/.testnets/bitcoin
	# TODO: Once vigilante implements a testnet command we will use that one instead of
	#  		manually creating and copying the config file
	mkdir -p $(CURDIR)/.testnets/vigilante
	cp $(CURDIR)/vigilante-bitcoind.yml $(CURDIR)/.testnets/vigilante/vigilante.yml
	# Start the docker compose
	docker-compose -f bitcoindsim.docker-compose.yml up -d explorer vigilante-reporter vigilante-submitter ibcsim babylondnode0 babylondnode1 nginx-proxy bitcoindsim

start-monitored-deployment-bitcoind: start-deployment-bitcoind
	docker-compose -f bitcoindsim.docker-compose.yml up -d prometheus grafana

stop-deployment-btcd:
	docker-compose -f btcdsim.docker-compose.yml down
	rm -rf $(CURDIR)/.testnets

stop-deployment-bitcoind:
	docker-compose -f bitcoindsim.docker-compose.yml down
	rm -rf $(CURDIR)/.testnets
