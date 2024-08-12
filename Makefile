start-deployment-btc-staking-integration-bitcoind:
	@$(MAKE) -C $(CURDIR)/deployments/btc-staking-integration-bitcoind \
		start-deployment-btc-staking-integration-bitcoind

start-deployment-btc-staking-integration-bitcoind-demo:
	@$(MAKE) -C $(CURDIR)/deployments/btc-staking-integration-bitcoind \
		NUM_VALIDATORS=${NUM_VALIDATORS} \
		start-deployment-btc-staking-integration-bitcoind-demo

stop-deployment-btc-staking-integration-bitcoind:
	@$(MAKE) -C $(CURDIR)/deployments/btc-staking-integration-bitcoind \
		stop-deployment-btc-staking-integration-bitcoind

start-deployment-finality-gadget-integration-op-l2-demo:
	@$(MAKE) -C $(CURDIR)/deployments/finality-gadget-integration-op-l2 \
		start

stop-deployment-finality-gadget-integration-op-l2:
	@$(MAKE) -C $(CURDIR)/deployments/finality-gadget-integration-op-l2 \
		stop