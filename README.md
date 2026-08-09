# XM360 Local MT5 Execution Bridge

Standalone Python Execution Bridge for **XM360 Millisecond Order Scheduler**.
Runs locally on any Windows PC or VPS logged into MetaTrader 5 ($0 Subscription / 100% Free Execution).

---

## ⚡ Quick Start (Windows)

1. **Launch MetaTrader 5**:
   Open MetaTrader 5 on your PC and log into your **XM Trading Account**.

2. **Run 1-Click Launcher**:
   Double-click **`start_bridge.bat`** (or open command prompt and run `python mt5_bridge.py`).

3. **Connect Web UI**:
   Open your **XM360 Order Scheduler Web App** -> Click **API Settings** -> Set **MetaApi Access Token** to:
   ```text
   http://localhost:8080
   ```
   *(If running on a remote PC/VPS, use `http://YOUR_PUBLIC_IP:8080`)*

---

## 📡 REST API Endpoints

* **`GET /health`**: Check MT5 Terminal connection status
* **`GET /account`**: Fetch live balance, equity, margin, leverage & currency
* **`GET /tickers`**: Fetch live bid/ask/spread for XAUUSD, Forex & Indices
* **`POST /trade`**: Execute instant MARKET or LIMIT orders with Stop Loss / Take Profit
