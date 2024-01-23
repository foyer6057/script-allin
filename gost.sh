#!/bin/bash

LATEST_VERSION=""

get_latest_version() {
    LATEST_VERSION="$(curl -sSL -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/go-gost/gost/releases" | grep -oP 'tag_name": "v\K[^"]+' | head -n 1)"
    if [[ -z "${LATEST_VERSION}" ]]; then
        echo "Failed to get latest version."
        exit 1
    fi
}

download_gost() {
    local temp_dir="$(mktemp -d)"
    cpu_info="$(cat "/proc/cpuinfo" | grep -oP 'model name\s+: \K.*' | head -n 1 | grep  -io 'v2')"
    local download_url="https://github.com/go-gost/gost/releases/download/v${LATEST_VERSION}/gost_${LATEST_VERSION}_linux_amd64v3.tar.gz"
    if [[ -n ${cpu_info} ]]; then
        download_url="https://github.com/go-gost/gost/releases/download/v${LATEST_VERSION}/gost_${LATEST_VERSION}_linux_amd64.tar.gz"
    fi
    curl -sSL -o "${temp_dir}/gost.tar.gz" "$download_url"
    tar xzvf "${temp_dir}/gost.tar.gz" -C "${temp_dir}"
    mv "${temp_dir}/gost" /home
    rm -rf "${temp_dir}"
}

write_startup_file() {
    cat << EOF > /etc/systemd/system/gost.service
[Unit]
Description=GO Simple Tunnel
After=network.target
Wants=network.target

[Service]
Type=simple
ExecStart=/usr/bin/gost -C /etc/gost/gost.yaml
Restart=always

[Install]
WantedBy=multi-user.target
EOF
}

add_configuration() {
    mkdir -p "/etc/gost"
    cat << EOF > /etc/gost/gost.yaml
services:
  - name: local
    addr: :8080
    handler:
      type: tcp
    listener:
      type: tcp
    forwarder:
      nodes:
        - name: remote
          addr: 192.168.1.1:80
EOF
}

main() {
    get_latest_version
    download_gost
    # write_startup_file
    # add_configuration
}

main
