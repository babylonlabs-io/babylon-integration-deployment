#!/bin/bash
set -euo pipefail

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install NVM if not already installed
if [ -s "$NVM_DIR/nvm.sh" ]; then
    echo "NVM is already installed."
else
    echo "Installing NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
fi
. "$NVM_DIR/nvm.sh"  # This loads nvm
nvm --version
echo

# Install Node if not already installed
if ! command_exists node; then
    echo "Installing Node..."
    nvm install 20
    nvm use 20
else
    echo "Node is already installed. Version: $(node --version)"
fi
node --version
npm --version
echo

# Install pnpm if not already installed
if ! command_exists pnpm; then
    echo "Installing pnpm..."
    npm install pnpm --global
else
    echo "pnpm is already installed. Version: $(pnpm --version)"
fi
pnpm --version
echo

# Check if Go is already installed
if command_exists go; then
    echo "Go is already installed. Version: $(go version)"
else
    # Install Golang
    echo "Installing Go..."
    wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
    tar -xzf go1.21.5.linux-amd64.tar.gz -C $HOME
    export GOROOT=$HOME/go
    export PATH=$PATH:$GOROOT/bin
    go version
fi
echo

# Install Foundry if not already installed
if ! command_exists forge; then
    echo "Installing Foundry..."
    if [[ "$(uname)" == "Linux" ]]; then
        curl -L https://github.com/foundry-rs/foundry/releases/download/nightly-$FOUNDRY_VERSION/foundry_nightly_linux_amd64.tar.gz | tar xvzf -
    elif [[ "$(uname)" == "Darwin" ]]; then # for MacOS
        curl -L https://github.com/foundry-rs/foundry/releases/download/nightly-$FOUNDRY_VERSION/foundry_nightly_darwin_amd64.tar.gz | tar xvzf -
    else
        echo "unsupported $(uname) system"
        exit 1
    fi
    mv forge cast anvil chisel $HOME/.foundry/bin
    export PATH=$HOME/.foundry/bin:$PATH
else
    echo "Foundry is already installed. Version: $(forge --version)"
fi
forge --version
echo

OP_DIR=$1
echo "OP_DIR: $OP_DIR"
cd $OP_DIR

# Install dependencies
echo "Installing dependencies..."
pnpm install
pnpm build
echo
