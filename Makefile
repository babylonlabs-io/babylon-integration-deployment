start-deployment-btcstaking-bitcoind:
	$(MAKE) -C $(CURDIR)/deployments/btcstaking-bitcoind \
		start-deployment-btcstaking-bitcoind

start-deployment-btcstaking-bitcoind-demo:
	$(MAKE) -C $(CURDIR)/deployments/btcstaking-bitcoind \
		NUM_VALIDATORS=${NUM_VALIDATORS} \
		start-deployment-btcstaking-bitcoind-demo

stop-deployment-btcstaking-bitcoind:
	$(MAKE) -C $(CURDIR)/deployments/btcstaking-bitcoind \
		stop-deployment-btcstaking-bitcoind

start-deployment-btcstaking-phase1-bitcoind:
	$(MAKE) -C $(CURDIR)/deployments/btcstaking-phase1-bitcoind \
		start-deployment-btcstaking-phase1-bitcoind

start-deployment-btcstaking-phase1-bitcoind-demo:
	$(MAKE) -C $(CURDIR)/deployments/btcstaking-phase1-bitcoind \
		start-deployment-btcstaking-phase1-bitcoind-demo

stop-deployment-btcstaking-phase1-bitcoind:
	$(MAKE) -C $(CURDIR)/deployments/btcstaking-phase1-bitcoind \
		stop-deployment-btcstaking-phase1-bitcoind

start-deployment-timestamping-bitcoind:
	$(MAKE) -C $(CURDIR)/deployments/timestamping-bitcoind \
		start-deployment-timestamping-bitcoind

stop-deployment-timestamping-bitcoind:
	$(MAKE) -C $(CURDIR)/deployments/timestamping-bitcoind \
		stop-deployment-timestamping-bitcoind

start-deployment-timestamping-btcd:
	$(MAKE) -C $(CURDIR)/deployments/timestamping-btcd \
		start-deployment-timestamping-btcd

stop-deployment-timestamping-btcd:
	$(MAKE) -C $(CURDIR)/deployments/timestamping-btcd \
		stop-deployment-timestamping-btcd

start-deployment-phase1-integration-bitcoind:
	$(MAKE) -C $(CURDIR)/deployments/phase1-integration-bitcoind \
		start-deployment-phase1-integration-bitcoind

stop-deployment-phase1-integration-bitcoind:
	$(MAKE) -C $(CURDIR)/deployments/phase1-integration-bitcoind \
		stop-deployment-phase1-integration-bitcoind

start-deployment-phase2-integration-bitcoind:
	$(MAKE) -C $(CURDIR)/deployments/phase2-integration-bitcoind \
		start-deployment-phase2-integration-bitcoind

stop-deployment-phase2-integration-bitcoind:
	$(MAKE) -C $(CURDIR)/deployments/phase2-integration-bitcoind \
		stop-deployment-phase2-integration-bitcoind

start-deployment-faucet:
	$(MAKE) -C $(CURDIR)/deployments/faucet start-deployment-faucet

stop-deployment-faucet:
	$(MAKE) -C $(CURDIR)/deployments/faucet stop-deployment-faucet

start-deployment-btc-discord-faucet:
	$(MAKE) -C $(CURDIR)/deployments/btc-discord-faucet start-deployment-btc-discord-faucet

stop-deployment-btc-discord-faucet:
	$(MAKE) -C $(CURDIR)/deployments/btc-discord-faucet stop-deployment-btc-discord-faucet

start-deployment-api:
	$(MAKE) -C $(CURDIR)/deployments/api start-deployment-api

stop-deployment-api:
	$(MAKE) -C $(CURDIR)/deployments/api stop-deployment-api
