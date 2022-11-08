DOCKER := $(shell which docker)

build-btcdsim:
	$(MAKE) -C contrib/images btcdsim

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

build-deployment-btcd: build-btcdsim build-babylond build-vigilante-reporter build-vigilante-submitter build-explorer

start-deployment-btcd: stop-deployment-btcd build-deployment-btcd
	$(DOCKER) run --rm -v $(CURDIR)/.testnets:/data babylonchain/babylond \
			  testnet init-files --v 4 -o /data \
			  --starting-ip-address 192.168.10.2 --keyring-backend=test \
			  --chain-id chain-test --btc-checkpoint-tag bbt0 --epoch-interval 10 \
			  --max-active-validators 2
	# volume in which the bitcoin configuration will be mounted
	mkdir -p $(CURDIR)/.testnets/bitcoin
	# TODO: Once vigilante implements a testnet command we will use that one instead of
	#  		manually creating and copying the config file
	mkdir -p $(CURDIR)/.testnets/vigilante
	cp $(CURDIR)/vigilante.yml $(CURDIR)/.testnets/vigilante/vigilante.yml
	# Start the docker compose
	docker-compose up -d babylondnode0 babylondnode1 babylondnode2 babylondnode3 \
						 btcdsim vigilante-reporter vigilante-submitter explorer nginx-proxy

run-deployment: stop-deployment
	docker-compose up -d babylondnode0 babylondnode1 babylondnode2 babylondnode3 \
						 btcdsim vigilante-reporter vigilante-submitter explorer nginx-proxy

stop-deployment:
	docker-compose down

stop-deployment-btcd: stop-deployment
	docker-compose down
	rm -rf $(CURDIR)/.testnets
