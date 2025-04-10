#!/bin/bash

set -e

# ===== 🪂 Banner =====
clear
echo "=============================================="
echo "🪂           AIRDROP LEGION                 "
echo "💬  Telegram: https://t.me/airdropalc"
echo "=============================================="
echo ""

# ===== Fungsi =====
function install_dependencies() {
    echo "🔄 Updating system & installing dependencies..."
    sudo apt update && sudo apt install -y git curl wget unzip tar build-essential
}

function install_foundry() {
    echo "⬇️ Installing Foundry..."
    curl -L https://foundry.paradigm.xyz | bash
    source /root/.bashrc
    foundryup
    forge --version
}

function install_vlayer() {
    echo "⬇️ Installing Vlayer..."
    curl -SL https://install.vlayer.xyz | bash
    source /root/.bashrc
    vlayerup
    vlayer --version
}

function install_bun() {
    echo "⬇️ Installing Bun..."
    curl -fsSL https://bun.sh/install | bash
    source /root/.bashrc
}

function setup_project() {
    read -p "📦 Masukkan nama project: " project_name
    read -p "🔑 Masukkan VLAYER_API_TOKEN: " api_token
    read -p "🔐 Masukkan EXAMPLES_TEST_PRIVATE_KEY: " private_key

    if [ -d "$project_name" ]; then
        echo "⚠️  Folder '$project_name' sudah ada!"
        read -p "Apakah kamu ingin menghapus folder tersebut dan melanjutkan? (y/n): " confirm
        if [[ "$confirm" == "y" ]]; then
            rm -rf "$project_name"
            echo "🗑️  Folder lama dihapus."
        else
            echo "❌ Dibatalkan."
            exit 1
        fi
    fi

    echo "🚀 Inisialisasi project $project_name ..."
    vlayer init "$project_name" --template simple-web-proof
    cd "$project_name"
    forge build

    cd vlayer

    echo "✍️ Membuat file .env.testnet.local ..."
    cat <<EOF > .env.testnet.local
VLAYER_API_TOKEN=$api_token
EXAMPLES_TEST_PRIVATE_KEY=$private_key
CHAIN_NAME=optimismSepolia
JSON_RPC_URL=https://sepolia.optimism.io
EOF

    echo "📦 Memastikan semua dependency terinstall..."
    if [ ! -f package.json ]; then
        echo "❌ package.json tidak ditemukan! Proses dihentikan."
        exit 1
    fi

    if ! grep -q "@vlayer/sdk" package.json; then
        echo "➕ Menambahkan @vlayer/sdk ..."
        bun add @vlayer/sdk
    fi

    echo "📥 Menjalankan bun install ..."
    bun install

    echo "▶️ Menjalankan VLAYER_ENV=testnet bun run prove.ts setiap 5 detik (tekan CTRL+C untuk berhenti) ..."
    while true; do
        echo "\$ VLAYER_ENV=testnet bun run prove.ts"
        if ! VLAYER_ENV=testnet bun run prove.ts; then
            echo "❌ Gagal menjalankan prove.ts. Pastikan semua modul sudah terinstall!"
        fi
        echo "⏳ Menunggu 5 detik..."
        sleep 5
    done
}

# ===== MENU =====
echo "🛠️  Pilih yang mau kamu lakukan:"
echo "1) Install Semua (Dependencies, Foundry, Vlayer, Bun)"
echo "2) Install Foundry saja"
echo "3) Install Vlayer saja"
echo "4) Install Bun saja"
echo "5) Setup Project Vlayer"
echo "6) Keluar"

read -p "Masukkan pilihan [1-6]: " pilihan

case $pilihan in
    1)
        install_dependencies
        install_foundry
        install_vlayer
        install_bun
        ;;
    2)
        install_dependencies
        install_foundry
        ;;
    3)
        install_dependencies
        install_vlayer
        ;;
    4)
        install_dependencies
        install_bun
        ;;
    5)
        setup_project
        ;;
    6)
        echo "❌ Tidak ada aksi diambil."
        exit 0
        ;;
    *)
        echo "⚠️  Pilihan tidak valid."
        exit 1
        ;;
esac

echo "✅ Proses selesai!"
