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

# Start demo
.PHONY: demo-start
demo-start: start-babylond
	sleep 2
	@$(MAKE) deploy-cw-contract

.PHONY: demo-test
demo-test:
	@$(MAKE) deploy-cw-contract