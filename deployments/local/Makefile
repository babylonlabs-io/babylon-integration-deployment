DOCKER := $(shell which docker)
GIT_TOPLEVEL := $(shell git rev-parse --show-toplevel)


build-babylond:
	$(MAKE) -C $(GIT_TOPLEVEL)/babylon build

build-vigilante:
	$(MAKE) -C $(GIT_TOPLEVEL)/vigilante build

build-fpd:
	$(MAKE) -C $(GIT_TOPLEVEL)/finality-provider build

build-covd:
	$(MAKE) -C $(GIT_TOPLEVEL)/covenant-emulator build

build-btc-staker:
	$(MAKE) -C $(GIT_TOPLEVEL)/btc-staker build

build-all: build-babylond build-vigilante build-fpd build-covd build-btc-staker

start-phase-2-full-test: build-all
	./phase-2-full-test.sh

start-bbn-with-btc-delegation: build-all
	./single-node-with-btc-delegation.sh

upgrade-vanilla: build-all
	./single-node.sh
	sleep 10
	./upgrade-single-node.sh

stop-all:
	./kill-all-process.sh
	rm -rf $(CURDIR)/data
