#!/bin/sh

# setup.sh
# usage: ./setup.sh #MEM [#CONNECTIONS]

FORWARDER_DIR="00_forwarder.work.win"
SERVER_CONFIG_DIR="01_server-config"
CLIENT_CONFIG_DIR="02_client-config"

function build_forwarder() {
make DSE_MEM=$1
}

function install_forwarder() {
make install
}

echo "This script is under construction"
exit 0

if [ $# -lt 1 ]; then
  echo "Usage: $0 #MEMBER [#CONNECTIONS]"
  exit 1
fi

DSE_MEM="$1"
build_forwarder $DSE_MEM
install_forwarder

# now write configuration files for PPP and inittab
