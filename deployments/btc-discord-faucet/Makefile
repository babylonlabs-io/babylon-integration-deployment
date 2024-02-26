DOCKER := $(shell which docker)
GIT_TOPLEVEL := $(shell git rev-parse --show-toplevel)

build-btc-discord-faucet:
	$(MAKE) -C $(GIT_TOPLEVEL)/btc-discord-faucet build-docker

build-deployment-btc-discord-faucet: build-btc-discord-faucet

start-deployment-btc-discord-faucet: stop-deployment-btc-discord-faucet build-deployment-btc-discord-faucet
	docker compose -f artifacts/docker-compose.yml up -d

stop-deployment-btc-discord-faucet:
	docker compose -f artifacts/docker-compose.yml down
