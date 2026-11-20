#!/usr/bin/env bash
# ==============================================================================
# Project 3: High-Throughput WireGuard VPN Gateway
# Author: Muhammadqodir Davlatyorov
# Safe deployment for shared VPS environments (HestiaCP / cPanel friendly)
# ==============================================================================
set -euo pipefail
cd "$(dirname "$0")"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}======================================================${NC}"
echo -e "${GREEN}   WireGuard VPN Gateway - Safe Docker Deployment     ${NC}"
echo -e "${BLUE}======================================================${NC}"

# Check Docker & Docker Compose
command -v docker >/dev/null || { echo -e "${RED}[ERROR] docker is not installed${NC}"; exit 1; }
docker compose version >/dev/null 2>&1 || { echo -e "${RED}[ERROR] docker compose v2 plugin missing${NC}"; exit 1; }

# Detect Server Public IP
SERVER_IP=$(curl -s -4 https://ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')

# Initialize .env with auto-generated secure password if missing
if [ ! -f .env ]; then
  if [ -f .env.example ]; then
    echo -e "${YELLOW}[*] Generating secure .env configuration...${NC}"
    cp .env.example .env
    
    # Safe password generation without SIGPIPE pipefail traps
    if command -v python3 >/dev/null 2>&1; then
      RANDOM_PASS=$(python3 -c "import secrets; print(secrets.token_urlsafe(18))")
    else
      RANDOM_PASS=$(openssl rand -base64 18 | tr -dc 'A-Za-z0-9_!@#' | head -c 20 || echo "WireGuardSecurePass$(date +%s)")
    fi

    sed -i "s|INIT_PASSWORD=|INIT_PASSWORD=${RANDOM_PASS}|" .env
    sed -i "s|INIT_HOST=<SERVER_IP>|INIT_HOST=${SERVER_IP}|" .env
    echo -e "${GREEN}[+] Generated Web UI admin password: ${YELLOW}${RANDOM_PASS}${NC}"
  else
    echo -e "${RED}[ERROR] .env.example template is missing!${NC}"
    exit 1
  fi
fi

# Load variables
set -a; . ./.env; set +a
WG_PORT="${WG_PORT:-51820}"
WG_UI_PORT="${WG_UI_PORT:-51821}"

# Ensure directories exist
mkdir -p wg
chmod 700 wg

# Ensure shared bridge network exists
if ! docker network inspect gateway >/dev/null 2>&1; then
  echo -e "${BLUE}[*] Creating shared bridge network 'gateway' (172.28.0.0/24)...${NC}"
  docker network create --subnet=172.28.0.0/24 gateway
fi

# Enable IP forwarding in kernel
if [ "$(cat /proc/sys/net/ipv4/ip_forward 2>/dev/null || echo 0)" != "1" ]; then
  echo -e "${BLUE}[*] Enabling net.ipv4.ip_forward in Linux kernel...${NC}"
  sysctl -w net.ipv4.ip_forward=1 >/dev/null 2>&1 || true
fi

echo -e "${BLUE}[*] Pulling and starting WireGuard container...${NC}"
docker compose pull
docker compose up -d

echo ""
echo -e "${GREEN}======================================================${NC}"
echo -e "${GREEN} [SUCCESS] WireGuard VPN Gateway is active!           ${NC}"
echo -e "${GREEN}======================================================${NC}"
echo -e "WireGuard UDP  : ${GREEN}${WG_PORT}/UDP${NC} (open to internet)"
echo -e "Web Management : ${YELLOW}127.0.0.1:${WG_UI_PORT}${NC} (loopback only)"
echo -e "DNS Upstream   : ${BLUE}${WG_DNS}${NC} (AdGuard Home)"
echo -e ""
echo -e "How to connect from laptop & scan QR code for phone:"
echo -e "  1. On laptop, open SSH tunnel:"
echo -e "     ${BLUE}ssh -L ${WG_UI_PORT}:127.0.0.1:${WG_UI_PORT} root@${SERVER_IP}${NC}"
echo -e "  2. In laptop browser open:"
echo -e "     ${GREEN}http://localhost:${WG_UI_PORT}${NC}"
echo -e "  3. Log in with:"
echo -e "     Username : ${YELLOW}admin${NC}"
echo -e "     Password : ${YELLOW}${INIT_PASSWORD}${NC}"
echo -e "  4. Click '+ New Client' and scan QR code with WireGuard app!"
echo -e "${GREEN}======================================================${NC}"
