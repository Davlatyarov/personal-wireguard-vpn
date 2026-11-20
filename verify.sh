#!/usr/bin/env bash
# ==============================================================================
# WireGuard Gateway Verification Script
# Read-only health check & diagnostic tool
# ==============================================================================
set -uo pipefail
cd "$(dirname "$0")"

pass() { printf '\033[32m  [PASS]\033[0m %s\n' "$*"; }
fail() { printf '\033[31m  [FAIL]\033[0m %s\n' "$*"; }
warn() { printf '\033[33m  [WARN]\033[0m %s\n' "$*"; }

[ -f .env ] && { set -a; . ./.env; set +a; }
WG_PORT="${WG_PORT:-51820}"
WG_UI_PORT="${WG_UI_PORT:-51821}"

echo "== 1. Container Status =="
if [ "$(docker inspect -f '{{.State.Running}}' wg-easy 2>/dev/null)" = "true" ]; then
  pass "wg-easy container is active and running"
else
  fail "wg-easy is NOT running (check: docker compose logs wg-easy)"
fi

echo ""
echo "== 2. Port Bindings & Security =="
ss -lun | grep -q ":${WG_PORT} " && pass "WireGuard port ${WG_PORT}/UDP is listening" || fail "Port ${WG_PORT}/UDP not listening"
if ss -ltn | grep -q "127.0.0.1:${WG_UI_PORT} "; then
  pass "Web Admin UI is securely bound to loopback (127.0.0.1:${WG_UI_PORT})"
elif ss -ltn | grep -q ":${WG_UI_PORT} "; then
  fail "SECURITY ALERT: Web UI is exposed publicly! Re-bind to 127.0.0.1"
else
  fail "Web UI port ${WG_UI_PORT} is not listening"
fi

echo ""
echo "== 3. Kernel IP Forwarding =="
if [ "$(cat /proc/sys/net/ipv4/ip_forward 2>/dev/null || echo 0)" = "1" ]; then
  pass "net.ipv4.ip_forward = 1 (kernel routing active)"
else
  fail "net.ipv4.ip_forward is disabled! Run: sysctl -w net.ipv4.ip_forward=1"
fi

echo ""
echo "== 4. WireGuard Tunnel Diagnostics =="
if docker exec wg-easy wg show 2>/dev/null | head -15; then
  peers=$(docker exec wg-easy wg show 2>/dev/null | grep -c '^peer:' || echo 0)
  pass "WireGuard interface active, ${peers} peer(s) registered"
else
  warn "WireGuard interface initializing — add a client in the web dashboard"
fi

echo ""
echo "== 5. Resource Consumption =="
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" wg-easy
