FROM debian:bullseye-slim

RUN apt-get update && apt-get install -y git make jq gcc make wget

WORKDIR /work

ARG TARGETARCH

ENV MACHINE $TARGETARCH

# Download and install Go
ENV GOLANG_VERSION 1.21.4
RUN wget -q https://golang.org/dl/go${GOLANG_VERSION}.linux-${MACHINE}.tar.gz && \
    tar -C /usr/local -xzf go${GOLANG_VERSION}.linux-${MACHINE}.tar.gz && \
    rm go${GOLANG_VERSION}.linux-${MACHINE}.tar.gz
# Set Go environment variables
ENV PATH /usr/local/go/bin:$PATH
ENV GOPATH /go
ENV PATH $GOPATH/bin:$PATH

WORKDIR /work

ENV GO111MODULE=on

# Install the relayer
RUN git clone https://github.com/cosmos/relayer.git
RUN cd relayer && git fetch origin && git checkout main && make install && cd -

# Install wasmd
RUN git clone https://github.com/CosmWasm/wasmd.git
RUN cd wasmd && git fetch origin && git checkout v0.50.0 && make install && cd -

WORKDIR /ibcsim-wasmd
COPY wrapper.sh /ibcsim-wasmd/wrapper.sh
COPY setup-wasmd.sh /ibcsim-wasmd/setup-wasmd.sh
COPY babylon-contract/artifacts/babylon_contract.wasm /ibcsim-wasmd/babylon_contract.wasm

ENV BABYLON_HOME=/data/node1/babylond
ENV BABYLON_NODE_RPC="http://babylondnode1:26657"
ENV RELAYER_CONF_DIR=/data/relayer
ENV WASMD_CONF=/data/wasmd
ENV UPDATE_CLIENTS_INTERVAL=20s

ENTRYPOINT ["/ibcsim-wasmd/wrapper.sh"]
CMD []
STOPSIGNAL SIGTERM
