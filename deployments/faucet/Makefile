DOCKER := $(shell which docker)
GIT_TOPLEVEL := $(shell git rev-parse --show-toplevel)

build-babylond:
	$(MAKE) -C $(GIT_TOPLEVEL)/babylon/contrib/images babylond

build-faucet:
	$(MAKE) -C $(GIT_TOPLEVEL)/faucet backend-docker-build

build-deployment-faucet: build-babylond build-faucet

start-deployment-faucet: stop-deployment-faucet build-deployment-faucet
	./pre-deployment.sh
	docker compose -f artifacts/docker-compose.yml up -d
	./post-deployment.sh

stop-deployment-faucet:
	docker compose -f artifacts/docker-compose.yml down
	rm -rf $(CURDIR)/.testnets
