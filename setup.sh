#!/bin/bash
set -e

echo "========================================================"
echo "🚀 Setting up mt5linux (Open Source MT5 Gateway for Linux)..."
echo "========================================================"

# 1. Start mt5linux container (Lucas Campagna open source server)
echo "🐳 Launching mt5linux server container..."
docker rm -f mt5linux_server 2>/dev/null || true
docker run -d \
  --name mt5linux_server \
  -p 18812:18812 \
  -p 8081:8080 \
  --restart always \
  lprett/mt5linux:latest

echo "⏳ Waiting 5 seconds for mt5linux server container..."
sleep 5

# 2. Setup Python virtual environment & install dependencies
echo "🐍 Setting up Python virtual environment and dependencies..."
if [ ! -d "venv" ]; then
  python3 -m venv venv
fi
source venv/bin/activate
pip install --upgrade pip setuptools wheel
pip install -r requirements.txt

# 3. Start mt5_bridge.py using venv Python
echo "⚙️ Starting MT5 Bridge service on port 8555..."
if command -v pm2 &> /dev/null; then
  pm2 delete mt5-bridge 2>/dev/null || true
  pm2 start "venv/bin/python mt5_bridge.py" --name mt5-bridge
  pm2 save
  echo "✅ Success! MT5 Bridge is running under PM2 on http://localhost:8555"
else
  pkill -f "mt5_bridge.py" || true
  nohup venv/bin/python mt5_bridge.py > bridge.log 2>&1 &
  echo "✅ Success! MT5 Bridge is running in background on http://localhost:8555"
fi

echo "========================================================"
echo "🌐 noVNC Web GUI: http://<YOUR_VM_IP>:8081"
echo "========================================================"
