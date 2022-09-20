DOCKER := $(shell which docker)

localnet-build-bitcoinsim:
	$(MAKE) -C contrib/images bitcoinsim

start-deployment: stop-deployment
	$(DOCKER) run --rm -v $(CURDIR)/.testnets:/data babylonchain/babylond \
			  testnet init-files --v 4 -o /data \
			  --starting-ip-address 192.168.10.2 --keyring-backend=test \
			  --chain-id chain-test --btc-checkpoint-tag bbt0
	# volume in which the bitcoin configuration will be mounted
	mkdir -p $(CURDIR)/.testnets/bitcoin
	# TODO: Once vigilante implements a testnet command we will use that one instead of
	#  		manually creating and copying the config file
	mkdir -p $(CURDIR)/.testnets/vigilante
	cp $(CURDIR)/vigilante.yml $(CURDIR)/.testnets/vigilante/vigilante.yml
	# Start the docker compose
	docker-compose up -d

stop-deployment:
	docker-compose down
	rm -rf $(CURDIR)/.testnets
