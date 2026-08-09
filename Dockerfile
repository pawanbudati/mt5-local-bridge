# Dockerfile for Headless MT5 Execution Bridge on GCP Linux VM
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV WINEPREFIX=/root/.wine
ENV DISPLAY=:99
ENV WINEDLLOVERRIDES="mscoree,mshtml="

# Install Wine, Xvfb, Wget, Curl & Certificates
RUN dpkg --add-architecture i386 && \
    apt-get update && apt-get install -y --no-install-recommends \
    wine64 \
    wine32 \
    xvfb \
    wget \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Download Windows Python 3.10 installer for Wine
RUN wget https://www.python.org/ftp/python/3.10.11/python-3.10.11-amd64.exe -O python-installer.exe && \
    xvfb-run wine python-installer.exe /quiet InstallAllUsers=1 PrependPath=1 && \
    rm python-installer.exe

# Copy bridge application files
COPY requirements.txt .
COPY mt5_bridge.py .
COPY start_linux.sh .

RUN chmod +x start_linux.sh

# Install MetaTrader5, Flask, and flask-cors inside Wine's Windows Python environment
RUN xvfb-run wine python -m pip install --no-cache-dir --upgrade pip setuptools wheel && \
    xvfb-run wine python -m pip install --no-cache-dir MetaTrader5 Flask flask-cors

EXPOSE 8555

CMD ["./start_linux.sh"]
