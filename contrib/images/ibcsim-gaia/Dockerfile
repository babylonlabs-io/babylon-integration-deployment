FROM golang:1.20-alpine AS build

RUN apk add --no-cache openssh-client git make build-base linux-headers libc-dev

WORKDIR /work

ENV GO111MODULE=on

# Install gaia
# NOTE: we need gaia that runs over go 1.20
RUN git clone https://github.com/cosmos/gaia.git
RUN cd gaia && git fetch origin && git checkout cb523c09bba68c1ac54e71bf4d4408628211532d && make install && cd -

# Install the relayer
RUN git clone https://github.com/babylonchain/babylon-relayer.git
RUN cd babylon-relayer && git checkout dev && make install && cd -

RUN apk add bash jq
WORKDIR /ibcsim-gaia
COPY wrapper.sh /ibcsim-gaia/wrapper.sh

ENV BABYLON_HOME=/data/node1/babylond
ENV BABYLON_NODE_RPC="http://babylondnode1:26657"
ENV RELAYER_CONF_DIR=/data/relayer
ENV GAIA_CONF=/data/gaia
ENV UPDATE_CLIENTS_INTERVAL=20s

ENTRYPOINT ["/ibcsim-gaia/wrapper.sh"]
CMD []
STOPSIGNAL SIGTERM
