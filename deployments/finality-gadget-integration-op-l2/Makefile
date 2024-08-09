GIT_TOPLEVEL := $(shell git rev-parse --show-toplevel)

# Start babylon localnet
.PHONY: start-babylond
start-babylond:
	cd $(GIT_TOPLEVEL)/babylon-private/ && \
	$(MAKE) localnet-start

# Deploy CW contract (from inside node0 container)
.PHONY: deploy-cw-contract
deploy-cw-contract:
	@./deploy-cw-contract.sh $(ARGS)

# Register OP consumer
.PHONY: register-op-consumer
register-op-consumer:
	@./register-op-consumer.sh $(ARGS)

# Start demo
.PHONY: demo-start
demo-start: start-babylond
	sleep 2
	@$(MAKE) deploy-cw-contract
	@$(MAKE) register-op-consumer
	# TODO: start local signet node
	# TODO: start eots manager
	# TODO: start OP
	# TODO: start FP

.PHONY: demo-test
demo-test:
	@$(MAKE) register-op-consumer