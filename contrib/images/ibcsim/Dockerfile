FROM golang:1.18-alpine AS build

RUN apk add --no-cache openssh-client git make build-base linux-headers libc-dev

WORKDIR /work

ENV GO111MODULE=on

# Install gaia
RUN git clone https://github.com/cosmos/gaia.git
RUN cd gaia && git checkout v7.0.3 && make install && cd -

# Install the relayer
RUN git clone https://github.com/cosmos/relayer.git
RUN cd relayer && git checkout v2.1.2 && make install && cd -

RUN apk add bash jq
WORKDIR /ibcsim
COPY wrapper.sh /ibcsim/wrapper.sh

ENV BABYLON_HOME=/data/node1/babylond
ENV BABYLON_NODE_RPC="http://babylondnode1:26657"
ENV RELAYER_CONF=/data/relayer
ENV GAIA_CONF=/data/gaia
ENV UPDATE_CLIENTS_INTERVAL_SEC=20
ENV IBC_PATHS_CONF=/ibcsim/ibc-paths
ENV IBC_CHAINS_CONF=/ibcsim/ibc-chains

ENTRYPOINT ["/ibcsim/wrapper.sh"]
CMD []
STOPSIGNAL SIGTERM
