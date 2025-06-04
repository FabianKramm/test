#!/bin/sh
set -e
set -o noglob

# Check if curl is installed
if ! command -v curl >/dev/null 2>&1; then
  echo "Error: curl is not installed. Please install curl and try again."
  exit 1
fi

# Check if systemctl is installed
if ! command -v systemctl >/dev/null 2>&1; then
  echo "Error: systemctl is not installed. This installer only works on systems that use systemd."
  exit 1
fi

# ensure we're running as root
if [ "$(id -u)" -ne 0 ]; then
  echo "Error: this installer needs the ability to run commands as root."
  exit 1
fi

# check if the architecture is arm
is_arm() {
  case "$(uname -a)" in
  *arm* ) true;;
  *arm64* ) true;;
  *aarch* ) true;;
  *aarch64* ) true;;
  * ) false;;
  esac
}

# --- set variables ---
DATA_DIR="/var/lib/vcluster"
SYSTEMD_DIR=/etc/systemd/system
FILE_VCLUSTER_SERVICE=${SYSTEMD_DIR}/vcluster.service
DOWNLOAD_URL=""
SKIP_DOWNLOAD="false"

# Parse command line arguments
while [ $# -gt 0 ]; do
  case "$1" in
    --download-url)
      DOWNLOAD_URL="$2"
      shift 2
      ;;
    --skip-download)
      SKIP_DOWNLOAD="true"
      shift 1
      ;;
    *)
      echo "Unknown argument: $1"
      exit 1
      ;;
  esac
done

# figure out the target architecture
TARGETARCH="amd64"
if is_arm; then
  TARGETARCH="arm64"
fi

# --- write systemd service file ---
create_systemd_service_file() {
    echo "Creating systemd service file ${FILE_VCLUSTER_SERVICE}"
    tee ${FILE_VCLUSTER_SERVICE} >/dev/null << EOF
[Unit]
Description=vcluster
Documentation=https://vcluster.com
Wants=network-online.target
After=network-online.target dbus.service

[Install]
WantedBy=multi-user.target

[Service]
Type=notify
EnvironmentFile=-/etc/default/%N
EnvironmentFile=-/etc/sysconfig/%N
KillMode=process
Delegate=yes
User=root
# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNOFILE=1048576
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
TimeoutStartSec=0
Restart=always
RestartSec=5s
ExecStart=${DATA_DIR}/bin/vcluster start --config ${DATA_DIR}/config.yaml

EOF
}

# --- create data dir ---
if [ "$SKIP_DOWNLOAD" = "false" ]; then
  # Kubernetes version is required
  if [ -z "$DOWNLOAD_URL" ]; then
    echo "Error: --download-url is required or specify --skip-download to skip the download"
    echo "Usage: $0 --download-url <url>"
    exit 1
  fi

  # Install vcluster binary
  mkdir -p ${DATA_DIR}
  mkdir -p ${DATA_DIR}/bin
  echo "Downloading vcluster binary..."
  curl -s -L -k -o ${DATA_DIR}/bin/vcluster ${DOWNLOAD_URL}
  chmod +x ${DATA_DIR}/bin/vcluster
fi

# --- create systemd service file ---
create_systemd_service_file

# --- start vcluster ---
echo "Starting vcluster..."
systemctl daemon-reload
systemctl enable --now vcluster.service

echo "Successfully installed vcluster"
