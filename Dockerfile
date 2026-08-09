# Dockerfile for Headless MT5 Execution Bridge on GCP Linux VM
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV WINEPREFIX=/root/.wine
ENV DISPLAY=:99
ENV WINEDLLOVERRIDES="mscoree,mshtml="

# Install Wine HQ / Ubuntu packages + Xvfb + Utilities
RUN dpkg --add-architecture i386 && \
    apt-get update && apt-get install -y --no-install-recommends \
    wine \
    wine64 \
    wine32 \
    xvfb \
    wget \
    curl \
    unzip \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Download & extract Windows Python 3.10 embedded package inside Wine drive_c
RUN mkdir -p /root/.wine/drive_c/Python310 && \
    wget https://www.python.org/ftp/python/3.10.11/python-3.10.11-embed-amd64.zip -O python.zip && \
    unzip python.zip -d /root/.wine/drive_c/Python310 && \
    rm python.zip && \
    sed -i 's/#import site/import site/' /root/.wine/drive_c/Python310/python310._pth

# Install pip for Wine Windows Python
RUN wget https://bootstrap.pypa.io/get-pip.py -O get-pip.py && \
    xvfb-run wine64 /root/.wine/drive_c/Python310/python.exe get-pip.py && \
    rm get-pip.py

# Install MetaTrader5, Flask & flask-cors inside Wine
RUN xvfb-run wine64 /root/.wine/drive_c/Python310/python.exe -m pip install --no-cache-dir MetaTrader5 Flask flask-cors

# Copy bridge application files
COPY requirements.txt .
COPY mt5_bridge.py .
COPY start_linux.sh .

RUN chmod +x start_linux.sh

EXPOSE 8555

CMD ["./start_linux.sh"]
