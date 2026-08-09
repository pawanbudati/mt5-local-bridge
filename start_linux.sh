#!/bin/bash
echo "========================================================"
echo "🚀 Starting Headless MT5 Bridge on GCP Linux VM..."
echo "========================================================"

# Start virtual display buffer for Wine
Xvfb :99 -screen 0 1024x768x16 > /dev/null 2>&1 &
sleep 1

export PORT=8555
python3 mt5_bridge.py
