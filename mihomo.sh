#!/bin/bash

add_startup() {
    cat << EOF > /etc/systemd/system/mihomo.service
[Unit]
Description=mihomo Daemon, Another Clash Kernel.
After=network.target NetworkManager.service systemd-networkd.service iwd.service

[Service]
Type=simple
LimitNPROC=500
LimitNOFILE=1000000
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_RAW CAP_NET_BIND_SERVICE CAP_SYS_TIME CAP_SYS_PTRACE CAP_DAC_READ_SEARCH
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_RAW CAP_NET_BIND_SERVICE CAP_SYS_TIME CAP_SYS_PTRACE CAP_DAC_READ_SEARCH
Restart=always
ExecStartPre=/usr/bin/sleep 1s
ExecStart=/usr/local/bin/mihomo -d /etc/mihomo
ExecReload=/bin/kill -HUP $MAINPID

[Install]
WantedBy=multi-user.target
EOF
}

add_configuration() {
    mkdir -p /etc/mihomo
    local pwd="$(openssl rand -base64 32)"
    local port=$((($RANDOM % 20000) + 10000))
    cat << EOF > /etc/mihomo/config.yaml
log-level: debug
tcp-concurrent: true
geodata-mode: true
geo-auto-update: true
geo-update-interval: 12
geodata-loader: standard
geox-url:
    geoip: "https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/release/geoip.dat"
    geosite: "https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/release/geosite.dat"
dns:
    enable: true
    nameserver:
        - https://1.1.1.1/dns-query

listeners:
    - name: ss-in
        type: shadowsocks
        port: $port
        listen: 0.0.0.0
        cipher: 2022-blake3-chacha20-poly1305
        password: $pwd
        udp: false

proxies:

rules:
    - GEOSITE,cambridge,DIRECT
    - GEOSITE,microsoft,DIRECT
    - GEOSITE,microsoft-dev,DIRECT
    - GEOSITE,cn,REJECT
    - GEOSITE,private,REJECT
    - GEOSITE,category-ads-all,REJECT
    - GEOIP,CN,REJECT,no-resolve
    - GEOIP,PRIVATE,REJECT,no-resolve
    - MATCH,DIRECT
EOF
}

install_mihomo() {
    local temp_dir="$(mktemp -d)"
    local latest_version="$(curl -sSL -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/MetaCubeX/mihomo/releases/latest |  grep -oP 'tag_name": "\K[^"]+')"
    local download_url="https://github.com/MetaCubeX/mihomo/releases/download/${latest_version}/mihomo-linux-amd64-go120-${latest_version}.gz"
    echo "Download from ${download_url}"
    curl -sSL -o "/usr/local/bin/mihomo.gz" "$download_url"
    rm -rf "${temp_dir}"
    gunzip "/usr/local/bin/mihomo.gz" && chmod +x "/usr/local/bin/mihomo"
}

main() {
    add_startup
    add_configuration
    install_mihomo
}

main
