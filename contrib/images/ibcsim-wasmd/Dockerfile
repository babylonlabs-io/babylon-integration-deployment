FROM debian:bullseye-slim AS build-env

RUN apt-get update && apt-get install -y git make gcc wget

WORKDIR /work

ARG TARGETARCH

# Download and install Go
ENV GOLANG_VERSION 1.21.4
RUN wget -q https://golang.org/dl/go${GOLANG_VERSION}.linux-${TARGETARCH}.tar.gz && \
    tar -C /usr/local -xzf go${GOLANG_VERSION}.linux-${TARGETARCH}.tar.gz && \
    rm go${GOLANG_VERSION}.linux-${TARGETARCH}.tar.gz
# Set Go environment variables
ENV PATH /usr/local/go/bin:$PATH
ENV GOPATH /go
ENV PATH $GOPATH/bin:$PATH

WORKDIR /work

ENV GO111MODULE on
#ENV RELAYER_TAG main
ENV RELAYER_TAG v2.5.2

# Install the relayer
RUN git clone https://github.com/cosmos/relayer.git
RUN cd relayer && git fetch origin && git checkout ${RELAYER_TAG} && make install && cd -

# Install wasmd
RUN git clone https://github.com/CosmWasm/wasmd.git
RUN cd wasmd && git fetch origin && git checkout v0.50.0 && make install && cd -

FROM debian:bullseye-slim AS run

RUN apt-get update && apt-get install -y bash curl jq wget

# Install libraries
# Cosmwasm - Download correct libwasmvm version
COPY --from=build-env /work/wasmd/go.mod /tmp
RUN WASMVM_VERSION=$(grep github.com/CosmWasm/wasmvm /tmp/go.mod | cut -d' ' -f2) && \
    wget https://github.com/CosmWasm/wasmvm/releases/download/$WASMVM_VERSION/libwasmvm.$(uname -m).so \
        -O /lib/libwasmvm.$(uname -m).so && \
    # verify checksum
    wget https://github.com/CosmWasm/wasmvm/releases/download/$WASMVM_VERSION/checksums.txt -O /tmp/checksums.txt && \
    sha256sum /lib/libwasmvm.$(uname -m).so | grep $(cat /tmp/checksums.txt | grep libwasmvm.$(uname -m) | cut -d ' ' -f 1)
RUN rm -f /tmp/go.mod

# Install binaries
COPY --from=build-env /go/bin/rly /usr/bin/rly
COPY --from=build-env /go/bin/wasmd /usr/bin/wasmd

WORKDIR /ibcsim-wasmd
COPY wrapper.sh /ibcsim-wasmd/wrapper.sh
COPY setup-wasmd.sh /ibcsim-wasmd/setup-wasmd.sh
# TODO: make a script to build the artifacts from babylon-contract submodule automatically, currently you have to manually build the wasm files only then the docker build will work
COPY babylon-contract/artifacts/babylon_contract.wasm /ibcsim-wasmd/babylon_contract.wasm
COPY babylon-contract/artifacts/btc_staking.wasm /ibcsim-wasmd/btc_staking.wasm

ENV BABYLON_HOME=/data/node1/babylond
ENV BABYLON_NODE_RPC="http://babylondnode1:26657"
ENV RELAYER_CONF_DIR=/data/relayer
ENV WASMD_CONF=/data/wasmd
ENV UPDATE_CLIENTS_INTERVAL=20s

ENTRYPOINT ["/ibcsim-wasmd/wrapper.sh"]
CMD []
STOPSIGNAL SIGTERM
