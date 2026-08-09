#!/bin/bash
echo "========================================================"
echo "🧹 Uninstalling & Cleaning MT5 Bridge packages from Linux VM..."
echo "========================================================"

# 1. Stop PM2 process & Docker container if running
echo "🛑 Stopping PM2 and Docker instances..."
pm2 delete mt5-bridge 2>/dev/null || true
docker rm -f mt5-bridge 2>/dev/null || true
pkill -f "mt5_bridge.py" 2>/dev/null || true
pkill -f "wine" 2>/dev/null || true
pkill -f "Xvfb" 2>/dev/null || true

# 2. Remove Wine prefix directory and cached files
echo "🗑️ Removing Wine configuration and Python files (~/.wine)..."
rm -rf ~/.wine ~/.cache/wine /tmp/.X*-lock /tmp/.X11-unix/X*

# 3. Purge Wine and Xvfb packages from apt
echo "📦 Purging Wine and Xvfb apt packages..."
sudo apt purge -y wine wine64 wine32 xvfb 2>/dev/null || true
sudo apt autoremove -y --purge
sudo apt clean

echo "========================================================"
echo "✅ Cleanup complete! All MT5 bridge dependencies removed."
echo "========================================================"
