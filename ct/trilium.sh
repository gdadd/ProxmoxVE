#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://triliumnext.github.io/Docs/

APP="Trilium"
var_tags="notes"
var_cpu="1"
var_ram="512"
var_disk="2"
var_os="debian"
var_version="12"
var_unprivileged="1"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/trilium ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if [[ ! -f /opt/${APP}_version.txt ]]; then touch /opt/${APP}_version.txt; fi
  RELEASE=$(curl -fsSL https://api.github.com/repos/TriliumNext/Notes/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [[ "v${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]] || [[ ! -f /opt/${APP}_version.txt ]]; then
    msg_info "Stopping ${APP}"
    systemctl stop trilium
    sleep 1
    msg_ok "Stopped ${APP}"

    msg_info "Updating to ${RELEASE}"
    mkdir -p /opt/trilium_backup
    mv /opt/trilium/{db,dump-db} /opt/trilium_backup/
    rm -rf /opt/trilium
    cd /tmp
    curl -fsSL "https://github.com/TriliumNext/Notes/releases/download/v${RELEASE}/TriliumNextNotes-Server-v${RELEASE}-linux-x64.tar.xz" -o $(basename"https://github.com/TriliumNext/Notes/releases/download/v${RELEASE}/TriliumNextNotes-Server-v${RELEASE}-linux-x64.tar.xz")
    tar -xf TriliumNextNotes-Server-v${RELEASE}-linux-x64.tar.xz
    mv TriliumNextNotes-Server-$RELEASE-linux-x64 /opt/trilium
    cp -r /opt/trilium_backup/{db,dump-db} /opt/trilium/
    echo "v${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Updated to ${RELEASE}"

    msg_info "Cleaning up"
    rm -rf /tmp/TriliumNextNotes-Server-${RELEASE}-linux-x64.tar.xz
    rm -rf /opt/trilium_backup
    msg_ok "Cleaned"

    msg_info "Starting ${APP}"
    systemctl start trilium
    sleep 1
    msg_ok "Started ${APP}"
    msg_ok "Updated Successfully"
  else
    msg_ok "No update required. ${APP} is already at ${RELEASE}"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080${CL}"
