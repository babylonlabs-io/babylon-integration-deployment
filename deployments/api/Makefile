DOCKER := $(shell which docker)
GIT_TOPLEVEL := $(shell git rev-parse --show-toplevel)
	
build-poller:
	$(MAKE) -C $(GIT_TOPLEVEL)/rpc-poller build-docker

build-api:
	$(MAKE) -C $(GIT_TOPLEVEL)/babylon-api build-docker

build-deployment-api: build-api build-poller

start-deployment-api: stop-deployment-api build-deployment-api
	./pre-deployment.sh
	docker compose -f artifacts/docker-compose.yml up -d

stop-deployment-api:
	docker compose -f artifacts/docker-compose.yml down
	rm -rf $(CURDIR)/.testnets
