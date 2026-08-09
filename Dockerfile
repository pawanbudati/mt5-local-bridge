# Dockerfile for Headless MT5 Execution Bridge on Linux VM
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV WINEPREFIX=/root/.wine
ENV DISPLAY=:99

# Install Wine, Xvfb, Python & Web Utilities
RUN dpkg --add-architecture i386 && \
    apt-get update && apt-get install -y --no-install-recommends \
    wine64 \
    wine32 \
    xvfb \
    wget \
    curl \
    python3 \
    python3-pip \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy bridge requirements and code
COPY requirements.txt .
COPY mt5_bridge.py .
COPY start_linux.sh .

RUN chmod +x start_linux.sh
RUN pip3 install --no-cache-dir Flask flask-cors

EXPOSE 8555

CMD ["./start_linux.sh"]
