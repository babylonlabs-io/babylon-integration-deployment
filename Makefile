start-deployment-btcstaking-bitcoind:
	$(MAKE) -C $(CURDIR)/deployments/btcstaking-bitcoind \
		BBN_PRIV_DEPLOY_KEY=${BBN_PRIV_DEPLOY_KEY} \
		start-deployment-btcstaking-bitcoind

start-deployment-btcstaking-bitcoind-demo:
	$(MAKE) -C $(CURDIR)/deployments/btcstaking-bitcoind \
		BBN_PRIV_DEPLOY_KEY=${BBN_PRIV_DEPLOY_KEY} \
		NUM_VALIDATORS=${NUM_VALIDATORS} \
		start-deployment-btcstaking-bitcoind-demo

stop-deployment-btcstaking-bitcoind:
	$(MAKE) -C $(CURDIR)/deployments/btcstaking-bitcoind \
		stop-deployment-btcstaking-bitcoind

start-deployment-timestamping-bitcoind:
	$(MAKE) -C $(CURDIR)/deployments/timestamping-bitcoind \
		BBN_PRIV_DEPLOY_KEY=${BBN_PRIV_DEPLOY_KEY} \
		start-deployment-timestamping-bitcoind

stop-deployment-timestamping-bitcoind:
	$(MAKE) -C $(CURDIR)/deployments/timestamping-bitcoind \
		stop-deployment-timestamping-bitcoind

start-deployment-timestamping-btcd:
	$(MAKE) -C $(CURDIR)/deployments/timestamping-btcd \
		BBN_PRIV_DEPLOY_KEY=${BBN_PRIV_DEPLOY_KEY} \
		start-deployment-timestamping-btcd

stop-deployment-timestamping-btcd:
	$(MAKE) -C $(CURDIR)/deployments/timestamping-btcd \
		stop-deployment-timestamping-btcd

start-deployment-phase1-integration-bitcoind:
	$(MAKE) -C $(CURDIR)/deployments/phase1-integration-bitcoind \
		BBN_PRIV_DEPLOY_KEY=${BBN_PRIV_DEPLOY_KEY} \
		start-deployment-phase1-integration-bitcoind

stop-deployment-phase1-integration-bitcoind:
	$(MAKE) -C $(CURDIR)/deployments/phase1-integration-bitcoind \
		stop-deployment-phase1-integration-bitcoind

start-deployment-phase2-integration-bitcoind:
	$(MAKE) -C $(CURDIR)/deployments/phase2-integration-bitcoind \
		BBN_PRIV_DEPLOY_KEY=${BBN_PRIV_DEPLOY_KEY} \
		start-deployment-phase2-integration-bitcoind

stop-deployment-phase2-integration-bitcoind:
	$(MAKE) -C $(CURDIR)/deployments/phase2-integration-bitcoind \
		stop-deployment-phase2-integration-bitcoind

start-deployment-faucet:
	$(MAKE) -C $(CURDIR)/deployments/faucet start-deployment-faucet

stop-deployment-faucet:
	$(MAKE) -C $(CURDIR)/deployments/faucet stop-deployment-faucet
