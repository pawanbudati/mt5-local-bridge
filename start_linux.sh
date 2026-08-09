#!/bin/bash
echo "========================================================"
echo "🚀 Starting Headless MT5 Bridge inside Wine on Linux VM..."
echo "========================================================"

# Start virtual display buffer for Wine
Xvfb :99 -screen 0 1024x768x16 > /dev/null 2>&1 &
sleep 2

export PORT=8555
wine64 /root/.wine/drive_c/Python310/python.exe mt5_bridge.py
