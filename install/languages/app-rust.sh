#!/usr/bin/env bash
set -euo pipefail
bash -c "$(curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs)" -- -y
echo "Rust installed via rustup"