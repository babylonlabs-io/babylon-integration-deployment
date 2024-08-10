#!/bin/sh
set -euo pipefail

# Install Node and pnpm
echo "Installing NVM..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.bashrc
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

# Install Rust
echo "Installing Rust..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"
rustc --version
cargo --version
echo

OP_DIR=$1
echo "OP_DIR: $OP_DIR"
cd $OP_DIR

echo "Installing dependencies..."
# Install dependencies
pnpm install

# Install Foundry
# pnpm install:foundry

echo "Installing Foundry..."
# Change the Foundry version in versions.json
FOUNDRY_VERSION="26a7559758c192911dd39ce7d621a18ef0d419e6"
jq --arg foundry_version "$FOUNDRY_VERSION" '.foundry = $foundry_version' versions.json > temp.json
mv temp.json versions.json

# Download the Foundry binary
curl -L https://github.com/foundry-rs/foundry/releases/download/nightly-$FOUNDRY_VERSION/foundry_nightly_linux_amd64.tar.gz | tar xvzf -
mv forge ~/.cargo/bin
mv cast ~/.cargo/bin
mv anvil ~/.cargo/bin
mv chisel ~/.cargo/bin
forge --version
echo "Foundry installed"
echo