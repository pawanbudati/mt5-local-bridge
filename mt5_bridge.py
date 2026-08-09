"""
XM360 Order Scheduler - Standalone Local MT5 Python Execution Bridge
Runs locally on any Windows PC or Windows VPS with MetaTrader 5 installed.

Features:
- High-precision execution for FX, Gold (XAUUSD), Indices, and Commodities.
- REST Endpoints: /health, /account, /tickers, /trade
"""

import sys
import time
from flask import Flask, request, jsonify

try:
    from flask_cors import CORS
    HAS_CORS = True
except ImportError:
    HAS_CORS = False

try:
    import MetaTrader5 as mt5
    MT5_AVAILABLE = True
except ImportError:
    MT5_AVAILABLE = False

app = Flask(__name__)
if HAS_CORS:
    CORS(app)

import os

MT5_TERMINAL_PATH = os.environ.get(
    'MT5_PATH',
    r"C:\Program Files\MetaTrader 5\terminal64.exe"
)

def ensure_mt5_connected(account_id=None, password=None, server_name=None):
    if not MT5_AVAILABLE:
        return False

    # Check if already connected & logged in
    try:
        term = mt5.terminal_info()
        acc = mt5.account_info()
        if term and acc:
            return True
    except Exception:
        pass

    # Try initializing MT5 terminal safely
    init_success = False
    try:
        if os.path.exists(MT5_TERMINAL_PATH):
            init_success = mt5.initialize(path=MT5_TERMINAL_PATH)
        else:
            init_success = mt5.initialize()
    except Exception as e:
        print(f"⚠️ Exception during mt5.initialize(): {e}")
        return False

    if not init_success:
        try:
            print(f"⚠️ mt5.initialize() failed: {mt5.last_error()}")
        except Exception:
            pass
        return False

    # Try explicit credential login
    if account_id and password:
        try:
            acc_num = int(account_id)
            srv = server_name or "XMGlobal-Real 30"
            print(f"🔑 Attempting MT5 login for account {acc_num} on server '{srv}'...")
            if mt5.login(login=acc_num, password=password, server=srv):
                print(f"✅ Successfully logged into MT5 Account {acc_num}!")
                return True
            else:
                print(f"⚠️ MT5 login failed: {mt5.last_error()}")
        except Exception as e:
            print(f"⚠️ MT5 login error: {e}")

    try:
        return mt5.terminal_info() is not None and mt5.account_info() is not None
    except Exception:
        return False

@app.route('/health', methods=['GET'])
def health():
    connected = ensure_mt5_connected()
    acc_info = None
    if connected:
        try:
            acc_info = mt5.account_info()
        except Exception:
            pass

    return jsonify({
        "status": "online",
        "mt5_connected": connected,
        "account_id": getattr(acc_info, 'login', None) if acc_info else None,
        "company": getattr(acc_info, 'company', None) if acc_info else None,
        "server": getattr(acc_info, 'server', None) if acc_info else None,
    })

@app.route('/connect', methods=['POST'])
def connect_account():
    if not MT5_AVAILABLE:
        return jsonify({
            "success": False,
            "error": "MetaTrader5 Python library is not installed."
        }), 400

    data = request.json or {}
    acc = data.get('account') or data.get('accountId')
    pwd = data.get('password')
    srv = data.get('server') or data.get('serverName') or 'XMGlobal-Real 30'

    if not acc or not pwd:
        return jsonify({"success": False, "error": "Account ID and Password required"}), 400

    connected = ensure_mt5_connected(acc, pwd, srv)
    info = None
    if connected:
        try:
            info = mt5.account_info()
        except Exception:
            pass

    if connected and info:
        return jsonify({
            "success": True,
            "message": f"Connected to MT5 Account {info.login}",
            "account_id": info.login,
            "server": info.server
        })
    else:
        err_msg = "Could not initialize MT5 terminal inside Wine environment."
        try:
            err_msg = str(mt5.last_error())
        except Exception:
            pass
        return jsonify({"success": False, "error": f"Failed to connect MT5 terminal: {err_msg}"}), 400

@app.route('/account', methods=['GET'])
def get_account():
    if not MT5_AVAILABLE:
        return jsonify({
            "success": False,
            "error": "MetaTrader5 Python library is not installed on this Linux OS. Please run mt5_bridge.py on your Windows PC/VPS."
        }), 400

    acc_id = request.args.get('account')
    pwd = request.args.get('password')
    srv = request.args.get('server')

    if not ensure_mt5_connected(acc_id, pwd, srv):
        return jsonify({"success": False, "error": f"MT5 terminal not connected: {mt5.last_error()}"}), 500

    acc = mt5.account_info()
    if not acc:
        return jsonify({"success": False, "error": f"Failed to fetch account info: {mt5.last_error()}"}), 500

    return jsonify({
        "success": True,
        "balance": acc.balance,
        "equity": acc.equity,
        "freeMargin": acc.margin_free,
        "usedMargin": acc.margin,
        "currency": acc.currency,
        "marginLevel": acc.margin_level,
        "leverage": acc.leverage,
        "accountId": str(acc.login),
        "server": acc.server
    })

@app.route('/tickers', methods=['GET'])
def get_tickers():
    if not MT5_AVAILABLE:
        return jsonify({"success": False, "error": "MetaTrader5 Python module not installed."}), 500

    if not ensure_mt5_connected():
        return jsonify({"success": False, "error": "MT5 terminal not connected"}), 500

    symbols = ["XAUUSD", "EURUSD", "GBPUSD", "USDJPY", "US30", "US500", "BTCUSD"]
    tickers = []
    for sym in symbols:
        mt5.symbol_select(sym, True)
        tick = mt5.symbol_info_tick(sym)
        if tick:
            spread = round(abs(tick.ask - tick.bid), 5)
            tickers.append({
                "symbol": sym,
                "lastPrice": tick.ask,
                "bidPrice": tick.bid,
                "askPrice": tick.ask,
                "priceChangePercent": 0.0,
                "high24h": tick.ask,
                "low24h": tick.bid,
                "volume24h": float(getattr(tick, 'volume', 0)),
                "spread": spread
            })

    return jsonify({"success": True, "data": tickers})

@app.route('/trade', methods=['POST'])
def place_trade():
    if not MT5_AVAILABLE:
        return jsonify({"success": False, "error": "MetaTrader5 Python module is not installed."}), 500

    data = request.json or {}
    acc = data.get('account') or data.get('accountId')
    pwd = data.get('password')
    srv = data.get('server') or data.get('serverName')

    if not ensure_mt5_connected(acc, pwd, srv):
        return jsonify({"success": False, "error": f"Failed to connect to XM MT5 terminal: {mt5.last_error()}"}), 500

    data = request.json or {}
    symbol = data.get('symbol', 'XAUUSD').upper()
    action = data.get('action', 'BUY').upper()
    order_type_str = data.get('type', 'MARKET').upper()
    volume = float(data.get('volume', 0.01))
    sl = float(data.get('stopLoss', 0)) if data.get('stopLoss') else 0.0
    tp = float(data.get('takeProfit', 0)) if data.get('takeProfit') else 0.0

    # Ensure symbol is selected in Market Watch
    if not mt5.symbol_select(symbol, True):
        return jsonify({"success": False, "error": f"Symbol {symbol} not found in MT5 Market Watch."}), 400

    tick = mt5.symbol_info_tick(symbol)
    if not tick:
        return jsonify({"success": False, "error": f"Failed to fetch market tick for {symbol}."}), 400

    # Determine order action & price
    if order_type_str == 'LIMIT':
        limit_price = float(data.get('price', 0))
        if limit_price <= 0:
            limit_price = tick.ask if action == 'BUY' else tick.bid
        order_action = mt5.TRADE_ACTION_PENDING
        order_type = mt5.ORDER_TYPE_BUY_LIMIT if action == 'BUY' else mt5.ORDER_TYPE_SELL_LIMIT
        price = limit_price
    else:
        order_action = mt5.TRADE_ACTION_DEAL
        order_type = mt5.ORDER_TYPE_BUY if action == 'BUY' else mt5.ORDER_TYPE_SELL
        price = tick.ask if action == 'BUY' else tick.bid

    trade_request = {
        "action": order_action,
        "symbol": symbol,
        "volume": volume,
        "type": order_type,
        "price": price,
        "sl": sl,
        "tp": tp,
        "deviation": 20,
        "magic": 202608,
        "comment": "XM360 Precision Scheduler",
        "type_time": mt5.ORDER_TIME_GTC,
        "type_filling": mt5.ORDER_FILLING_IOC,
    }

    result = mt5.order_send(trade_request)
    if result is None or result.retcode != mt5.TRADE_RETCODE_DONE:
        err_code = result.retcode if result else mt5.last_error()
        err_msg = result.comment if result else str(mt5.last_error())
        return jsonify({
            "success": False,
            "error": f"MT5 Order Execution Failed [{err_code}]: {err_msg}",
            "retcode": err_code
        }), 400

    return jsonify({
        "success": True,
        "ticket": str(result.order),
        "price": result.price,
        "volume": result.volume,
        "symbol": symbol,
        "action": action,
        "comment": result.comment
    })

if __name__ == '__main__':
    import os
    port = int(os.environ.get('PORT', 8555))
    print("=" * 60)
    print("🚀 XM360 Local MT5 Execution Bridge")
    print(f"Listen URL: http://0.0.0.0:{port}")
    print("=" * 60)

    if MT5_AVAILABLE:
        if mt5.initialize():
            acc = mt5.account_info()
            if acc:
                print(f"✅ Connected to XM MT5 Terminal! Account: {acc.login} ({acc.server})")
            else:
                print("⚠️ MT5 initialized but no active account log in detected.")
        else:
            print(f"⚠️ Failed to initialize MT5 Terminal: {mt5.last_error()}")
    else:
        print("❌ MetaTrader5 module missing. Install via: pip install MetaTrader5")

    app.run(host='0.0.0.0', port=port)
