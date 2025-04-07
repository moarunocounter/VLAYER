#!/bin/bash

# =======================================================
#                     AIRDROP LEGION
# =======================================================
#  Telegram : @airdropalc
# =======================================================

# Pastikan script bisa digunakan oleh semua user tanpa perlu root secara langsung
if [ "$EUID" -ne 0 ]; then
    echo "Beberapa perintah memerlukan akses root. Meminta sudo..."
    exec sudo bash "$0"
    exit 1
fi

# Berikan izin eksekusi kepada semua user
chmod +x "$0"
chmod 755 "$0"

# Minta input user
read -p "Masukkan email Git kamu: " GIT_EMAIL
read -p "Masukkan username Git kamu: " GIT_USERNAME
read -p "Masukkan JWT Token Vlayer: " VLAYER_API_TOKEN
read -p "Masukkan Private Key Wallet kamu: " EXAMPLES_TEST_PRIVATE_KEY

# Update dan install dependensi
dpkg --configure -a
apt update && apt install -y git curl wget unzip tar build-essential

# Install Foundry
curl -L https://foundry.paradigm.xyz | bash && source ~/.bashrc && foundryup && forge --version

# Install Vlayer
curl -SL https://install.vlayer.xyz | bash && source ~/.bashrc && vlayerup && vlayer --version

# Install Bun
curl -fsSL https://bun.sh/install | bash && source ~/.bashrc && bun --version

# Konfigurasi Git
git config --global user.email "$GIT_EMAIL"
git config --global user.name "$GIT_USERNAME"

# Buat proyek baru
vlayer init "$GIT_USERNAME" --template simple-web-proof
cd "$GIT_USERNAME" || exit
forge build
cd vlayer || exit

# Buat file konfigurasi environment
echo "VLAYER_API_TOKEN=$VLAYER_API_TOKEN" > .env.testnet.local
echo "EXAMPLES_TEST_PRIVATE_KEY=$EXAMPLES_TEST_PRIVATE_KEY" >> .env.testnet.local
echo "CHAIN_NAME=optimismSepolia" >> .env.testnet.local
echo "JSON_RPC_URL=https://sepolia.optimism.io" >> .env.testnet.local

# Tampilkan isi file untuk verifikasi
cat .env.testnet.local

# Looping eksekusi transaksi di testnet setiap 5 detik
while true; do
    echo "Menjalankan transaksi di testnet..."
    bun run prove:testnet
    sleep 5
done
