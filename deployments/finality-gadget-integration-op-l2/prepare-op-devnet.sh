#!/bin/bash
set -euo pipefail

# Install Node and pnpm
echo "Installing NVM..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
export NVM_DIR="$HOME/.nvm"
# Loads nvm
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm --version
echo

echo "Installing Node..."
nvm install 20
nvm use 20
node --version
npm --version
echo

echo "Installing pnpm..."
npm install pnpm --global
pnpm --version
echo

# Check if Go is already installed
if command -v go &> /dev/null; then
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

# Install Foundry
echo "Installing Foundry..."
curl -L https://foundry.paradigm.xyz | bash
source $HOME/.bashrc
foundryup
echo 'export PATH=$HOME/.foundry/bin:$PATH' >> $BASH_ENV
source $HOME/.bashrc
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
