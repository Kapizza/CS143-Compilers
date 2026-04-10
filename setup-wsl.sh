#!/bin/bash
# ============================================================
#  CS143 — Cool Toolchain Setup for WSL
# ============================================================
#  Run this script once inside your WSL terminal:
#    bash setup-wsl.sh
# ============================================================

set -e  # stop on any error

echo "==> Installing system dependencies..."
sudo apt-get update -q
sudo apt-get install -y --no-install-recommends \
    wget \
    flex \
    bison \
    build-essential \
    csh \
    libxaw7-dev \
    libc6-i386 \
    lib32stdc++6 \
    lib32gcc-s1

echo "==> Creating /usr/class directory..."
sudo mkdir -p /usr/class
sudo chown "$USER" /usr/class

echo "==> Downloading Cool student distribution..."
wget -q --show-progress \
    "https://courses.edx.org/asset-v1:StanfordOnline+SOE.YCSCS1+1T2020+type@asset+block@student-dist.tar.gz" \
    -O /tmp/student-dist.tar.gz

echo "==> Extracting toolchain..."
tar -xzf /tmp/student-dist.tar.gz -C /usr/class
rm /tmp/student-dist.tar.gz

echo "==> Adding coolc and spim to PATH..."
PROFILE="$HOME/.bashrc"
if ! grep -q "/usr/class/bin" "$PROFILE"; then
    echo 'export PATH="/usr/class/bin:$PATH"' >> "$PROFILE"
fi

echo ""
echo "============================================"
echo "  Done! Run the following to apply PATH:"
echo "    source ~/.bashrc"
echo ""
echo "  Then test with:"
echo "    which coolc"
echo "============================================"
