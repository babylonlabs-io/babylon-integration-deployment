DOCKER := $(shell which docker)

build-btcdsim:
	$(MAKE) -C contrib/images btcdsim

build-bitcoindsim:
	$(MAKE) -C contrib/images bitcoindsim

build-ibcsim-gaia:
	$(MAKE) -C contrib/images ibcsim-gaia

build-ibcsim-wasmd:
	$(MAKE) -C contrib/images ibcsim-wasmd

build-babylond:
	# Hack: Go does not like it when using git submodules
	# See: https://github.com/golang/go/issues/53640
	cd babylon; mv .git .git.bk; cp -R ../.git/modules/babylon .git; $(MAKE) build-docker; rm -rf .git; mv .git.bk .git

build-vigilante:
	# Hack: Go does not like it when using git submodules
	# See: https://github.com/golang/go/issues/53640
	cd vigilante; mv .git .git.bk; cp -R ../.git/modules/vigilante .git; $(MAKE) build-docker; rm -rf .git; mv .git.bk .git

build-btc-staker:
	# Hack: Go does not like it when using git submodules
	# See: https://github.com/golang/go/issues/53640
	cd btc-staker; mv .git .git.bk; cp -R ../.git/modules/btc-staker .git; \
		$(MAKE) BBN_PRIV_DEPLOY_KEY=${BBN_PRIV_DEPLOY_KEY} build-docker build-docker; rm -rf .git; mv .git.bk .git

build-faucet:
	$(MAKE) -C faucet frontend-build
	$(MAKE) -C faucet backend-build

build-deployment-btcd: build-babylond build-btcdsim build-vigilante

build-deployment-bitcoind: build-babylond build-bitcoindsim build-vigilante

build-deployment-faucet: build-babylond build-faucet

build-deployment-btcstaking-bitcoind: build-babylond build-bitcoindsim build-vigilante build-btc-staker

start-deployment-btcstaking-bitcoind: stop-deployment-btcstaking-bitcoind build-deployment-btcstaking-bitcoind
	rm -rf $(CURDIR)/.testnets && mkdir -p $(CURDIR)/.testnets && chmod o+w $(CURDIR)/.testnets
	$(DOCKER) run --rm -v $(CURDIR)/.testnets:/data babylonchain/babylond \
			  babylond testnet init-files --v 2 -o /data \
			  --starting-ip-address 192.168.10.2 --keyring-backend=test \
			  --chain-id chain-test --epoch-interval 10 \
			  --btc-finalization-timeout 2 --btc-confirmation-depth 1 \
			  --minimum-gas-prices 0.000006ubbn \
			  --btc-base-header 0100000000000000000000000000000000000000000000000000000000000000000000003ba3edfd7a7b12b27ac72c3e67768f617fc81bc3888a51323a9fb8aa4b1e5e4adae5494dffff7f2002000000 \
			  --btc-network regtest --additional-sender-account
	# volume in which the bitcoin configuration will be mounted
	mkdir -p $(CURDIR)/.testnets/bitcoin
	# TODO: Once vigilante implements a testnet command we will use that one instead of
	#  		manually creating and copying the config file
	mkdir -p $(CURDIR)/.testnets/vigilante
	cp $(CURDIR)/vigilante-bitcoind.yml $(CURDIR)/.testnets/vigilante/vigilante.yml
	# volume in which the btc-staker configuration will be mounted
	mkdir -p $(CURDIR)/.testnets/btc-staker
	cp $(CURDIR)/stakerd-bitcoind.conf $(CURDIR)/.testnets/btc-staker/stakerd.conf
	# Start the docker compose
	docker-compose -f btc-staking-bitcoind.docker-compose.yml up -d
	# Create keyrings and send funds to Babylon Node Consumers (stored on babylondnode0)
	sleep 15
	$(DOCKER) exec babylondnode0 /bin/sh -c ' \
		BTC_STAKER_ADDR=$$(/bin/babylond --home /babylondhome keys add \
			btc-staker --output json | jq -r .address) && \
		/bin/babylond --home /babylondhome tx bank send test-spending-key \
			$${BTC_STAKER_ADDR} 100000000ubbn --fees 2ubbn -y'
	sleep 15
	$(DOCKER) exec babylondnode0 /bin/sh -c ' \
		VIGILANTE_ADDR=$$(/bin/babylond --home /babylondhome keys add \
			vigilante --output json | jq -r .address) && \
		/bin/babylond --home /babylondhome tx bank send test-spending-key \
			$${VIGILANTE_ADDR} 100000000ubbn --fees 2ubbn -y'


start-deployment-btcd: stop-deployment-btcd build-deployment-btcd
	rm -rf $(CURDIR)/.testnets && mkdir -p $(CURDIR)/.testnets && chmod o+w $(CURDIR)/.testnets
	$(DOCKER) run --rm -v $(CURDIR)/.testnets:/data babylonchain/babylond \
			  babylond testnet init-files --v 2 -o /data \
			  --starting-ip-address 192.168.10.2 --keyring-backend=test \
			  --chain-id chain-test --epoch-interval 10 \
			  --minimum-gas-prices 0.000006ubbn \
			  --btc-finalization-timeout 2 --btc-confirmation-depth 1 \
			  --additional-sender-account
	# volume in which the bitcoin configuration will be mounted
	mkdir -p $(CURDIR)/.testnets/bitcoin
	# TODO: Once vigilante implements a testnet command we will use that one instead of
	#  		manually creating and copying the config file
	mkdir -p $(CURDIR)/.testnets/vigilante
	cp $(CURDIR)/vigilante-btcd.yml $(CURDIR)/.testnets/vigilante/vigilante.yml
	# Start the docker compose
	docker-compose -f btcdsim.docker-compose.yml up -d vigilante-reporter vigilante-submitter vigilante-monitor babylondnode0 babylondnode1 btcdsim
	# Create keyrings and send funds to Babylon Node Consumers (stored on babylondnode0)
	sleep 15
	$(DOCKER) exec babylondnode0 /bin/sh -c ' \
		VIGILANTE_ADDR=$$(/bin/babylond --home /babylondhome keys add \
			vigilante --output json | jq -r .address) && \
		/bin/babylond --home /babylondhome tx bank send test-spending-key \
			$${VIGILANTE_ADDR} 100000000ubbn --fees 2ubbn -y'

start-monitored-deployment-btcd: start-deployment-btcd
	docker-compose -f btcdsim.docker-compose.yml up -d prometheus grafana

start-deployment-bitcoind: stop-deployment-bitcoind build-deployment-bitcoind
	rm -rf $(CURDIR)/.testnets && mkdir -p $(CURDIR)/.testnets && chmod o+w $(CURDIR)/.testnets
	$(DOCKER) run --rm -v $(CURDIR)/.testnets:/data babylonchain/babylond \
			  babylond testnet init-files --v 2 -o /data \
			  --starting-ip-address 192.168.10.2 --keyring-backend=test \
			  --chain-id chain-test --epoch-interval 10 \
			  --btc-finalization-timeout 2 --btc-confirmation-depth 1 \
			  --minimum-gas-prices 0.000006ubbn \
			  --btc-base-header 0100000000000000000000000000000000000000000000000000000000000000000000003ba3edfd7a7b12b27ac72c3e67768f617fc81bc3888a51323a9fb8aa4b1e5e4adae5494dffff7f2002000000 \
			  --btc-network regtest --additional-sender-account
	# volume in which the bitcoin configuration will be mounted
	mkdir -p $(CURDIR)/.testnets/bitcoin
	# TODO: Once vigilante implements a testnet command we will use that one instead of
	#  		manually creating and copying the config file
	mkdir -p $(CURDIR)/.testnets/vigilante
	cp $(CURDIR)/vigilante-bitcoind.yml $(CURDIR)/.testnets/vigilante/vigilante.yml
	# Start the docker compose
	docker-compose -f bitcoindsim.docker-compose.yml up -d vigilante-reporter vigilante-submitter vigilante-monitor babylondnode0 babylondnode1 bitcoindsim
	# Create keyrings and send funds to Babylon Node Consumers (stored on babylondnode0)
	sleep 15
	$(DOCKER) exec babylondnode0 /bin/sh -c ' \
		VIGILANTE_ADDR=$$(/bin/babylond --home /babylondhome keys add \
			vigilante --output json | jq -r .address) && \
		/bin/babylond --home /babylondhome tx bank send test-spending-key \
			$${VIGILANTE_ADDR} 100000000ubbn --fees 2ubbn -y'

start-monitored-deployment-bitcoind: start-deployment-bitcoind
	docker-compose -f bitcoindsim.docker-compose.yml up -d prometheus grafana

start-deployment-bitcoind-phase1: build-ibcsim-gaia start-deployment-bitcoind
	docker-compose -f bitcoindsim.docker-compose.yml up -d ibcsim-gaia

start-deployment-bitcoind-phase2: build-ibcsim-wasmd start-deployment-bitcoind
	docker-compose -f bitcoindsim.docker-compose.yml up -d ibcsim-wasmd

start-deployment-faucet: stop-deployment-faucet build-deployment-faucet
	$(DOCKER) run --rm -v $(CURDIR)/.testnets:/data babylonchain/babylond \
				  testnet init-files --v 2 -o /data \
				  --starting-ip-address 192.168.10.2 --keyring-backend=test \
				  --chain-id chain-test --btc-checkpoint-tag bbt0 --epoch-interval 10 \
				  --minimum-gas-prices 0.000006ubbn \
				  --btc-finalization-timeout 2 --btc-confirmation-depth 1
	mkdir -p $(CURDIR)/.testnets/faucet
	cp $(CURDIR)/faucet-config.yml $(CURDIR)/.testnets/faucet/config.yml
	# Start the docker compose
	docker-compose -f faucet.docker-compose.yml up -d babylondnode0 babylondnode1 faucet-frontend faucet-backend

stop-deployment-btcd:
	docker-compose -f btcdsim.docker-compose.yml down
	rm -rf $(CURDIR)/.testnets

stop-deployment-bitcoind:
	docker-compose -f bitcoindsim.docker-compose.yml down
	rm -rf $(CURDIR)/.testnets

stop-deployment-btcstaking-bitcoind:
	docker-compose -f btc-staking-bitcoind.docker-compose.yml down
	rm -rf $(CURDIR)/.testnets

stop-deployment-faucet:
	docker-compose -f faucet.docker-compose.yml down
	rm -rf $(CURDIR)/.testnets
