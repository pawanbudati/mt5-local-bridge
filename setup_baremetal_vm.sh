#!/bin/bash
set -e

echo "========================================================"
echo "🚀 Setting up Headless MT5 Bridge directly on Linux VM (No Docker)..."
echo "========================================================"

# Clean any stale lockfiles
rm -f /tmp/.X*-lock /tmp/.X11-unix/X* 2>/dev/null || true

# 1. Install Wine & Xvfb
echo "📦 Installing Wine and Xvfb..."
sudo dpkg --add-architecture i386 || true
sudo apt update -y
sudo apt install -y wine64 wine32 xvfb wget curl unzip ca-certificates

# 2. Setup Windows Python 3.10 inside Wine
echo "🐍 Setting up Windows Python 3.10 inside Wine..."
export WINEDEBUG=-all
xvfb-run -a winecfg -v win10 || true
mkdir -p ~/.wine/drive_c/Python310
if [ ! -f ~/.wine/drive_c/Python310/python.exe ]; then
  wget -q https://www.python.org/ftp/python/3.10.11/python-3.10.11-embed-amd64.zip -O python.zip
  unzip -q python.zip -d ~/.wine/drive_c/Python310
  rm python.zip
  sed -i 's/#import site/import site/' ~/.wine/drive_c/Python310/python310._pth
fi

# 3. Install pip, MetaTrader5, Flask inside Wine
echo "📦 Installing MetaTrader5 & Flask inside Wine..."
if [ ! -f ~/.wine/drive_c/Python310/Scripts/pip.exe ]; then
  wget -q https://bootstrap.pypa.io/get-pip.py -O get-pip.py
  xvfb-run -a wine64 ~/.wine/drive_c/Python310/python.exe get-pip.py
  rm get-pip.py
fi

xvfb-run -a wine64 ~/.wine/drive_c/Python310/python.exe -m pip install --upgrade MetaTrader5 Flask flask-cors

# 4. Start via PM2
echo "⚙️ Starting MT5 Bridge via PM2..."
if command -v pm2 &> /dev/null; then
  pm2 delete mt5-bridge 2>/dev/null || true
  pm2 start "WINEDEBUG=-all xvfb-run -a wine64 ~/.wine/drive_c/Python310/python.exe mt5_bridge.py" --name mt5-bridge
  pm2 save
  echo "✅ Success! MT5 Bridge is running under PM2 on http://localhost:8555"
else
  echo "⚠️ PM2 not found. Starting via background process..."
  pkill -f "mt5_bridge.py" || true
  nohup xvfb-run -a wine64 ~/.wine/drive_c/Python310/python.exe mt5_bridge.py > bridge.log 2>&1 &
  echo "✅ Success! MT5 Bridge is running in background on http://localhost:8555"
fi
echo "========================================================"
