# MT5 Local Execution Bridge

Standalone Python Execution Bridge for **XM Order Scheduler**, powered by Lucas Campagna's open-source `mt5linux` server.

Runs on Linux VM or Windows PC listening on port `8555`.

---

## 🚀 1-Click Setup on GCP Linux VM

```bash
cd ~/mt5-local-bridge
git pull origin main
chmod +x setup.sh
./setup.sh
```

---

## ⚡ 1-Click Setup on Windows PC / VPS

1. Open MetaTrader 5 terminal on your PC.
2. Double-click `start_bridge.bat` (or run `python mt5_bridge.py`).

---

## 📡 REST API Endpoints (Port 8555)

* **`GET /health`**: Check MT5 status
* **`POST /connect`**: Connect to XM MT5 Account (`account`, `password`, `server`)
* **`GET /account`**: Live balance, equity, leverage
* **`POST /trade`**: Execute Market & Pending Orders with SL/TP
