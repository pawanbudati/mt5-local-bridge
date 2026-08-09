@echo off
title XM360 Local MT5 Execution Bridge
echo ========================================================
echo   XM360 Local MT5 Execution Bridge
echo   Connecting MetaTrader 5 Terminal with Cloud Scheduler...
echo ========================================================
echo.

python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Error: Python is not installed or not in PATH.
    echo Please install Python 3.10+ from python.org and check "Add Python to PATH".
    pause
    exit /b
)

echo 📦 Installing dependencies...
pip install -r requirements.txt

echo.
echo 🚀 Starting XM360 MT5 Local Execution Bridge on http://localhost:8080...
python mt5_bridge.py

pause
