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

# Install Rust
echo "Installing Rust..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
export PATH="$HOME/.cargo/bin:$PATH"
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

# Modify the Makefile to ensure that the forge binary can be found when running the devnet-up target in the Makefile.
modify_makefile() {
    local makefile_path="$OP_DIR/Makefile"
    local target="devnet-up"
    local insert_line='export PATH="$$HOME/.cargo/bin:$$PATH" && \\'

    # Check if the line already exists to avoid duplicate insertions
    if ! grep -q "$insert_line" "$makefile_path"; then
        # Find the line number of the devnet-up target
        local line_number=$(grep -n "^$target:" "$makefile_path" | cut -d: -f1)

        # Insert the new line after the target line
        sed -i "${line_number}a\\       $insert_line" "$makefile_path"

        echo "Modified Makefile to add PATH export for devnet-up target"
    else
        echo "PATH export already exists in devnet-up target"
    fi
}
modify_makefile
echo