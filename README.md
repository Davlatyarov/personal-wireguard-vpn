# Personal VPN Gateway & Anti-Censorship Tunnel (WireGuard + VLESS Reality)

[![WireGuard](https://img.shields.io/badge/WireGuard-Kernel--Mode-88171A?logo=wireguard&logoColor=white)](https://www.wireguard.com/)
[![Xray](https://img.shields.io/badge/Xray-VLESS%20Reality-blue?logo=xray)](https://github.com/XTLS/Xray-core)
[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![BBR](https://img.shields.io/badge/TCP%20BBR-Google%20Optimized-success)](https://github.com/google/bbr)
[![Security](https://img.shields.io/badge/DPI--Resistant-Anti--Censorship-green.svg)](https://github.com/Davlatyarov/personal-wireguard-vpn)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A hardened, enterprise-grade **Personal VPN Gateway & Anti-Censorship Ingress System** designed to operate reliably across restrictive network environments and hostile Deep Packet Inspection (DPI) firewalls. Engineered alongside **Project 2: Personal Secure Gateway** for unified ad-blocking, telemetry sinkholing, and betting site interception.

Developed by **Muhammadqodir Davlatyorov** (BSc Cybersecurity Student at International Digital University / University of Wolverhampton programme).

---

## Architecture Overview

```
 [ Client Devices: Android / iOS / Windows / macOS ]
                         |
      +------------------+------------------+
      | (Standard Networks)                 | (DPI-Restricted Networks)
      | [WireGuard / UDP 51820]             | [VLESS + XTLS Reality / TCP 2053]
      |                                     | Masked as: www.microsoft.com
      v                                     v
+-------------------------------------------------------------------------------+
| Linux VPS Host (<SERVER_IP>)                                                  |
|                                                                               |
|   +-----------------------------------------------------------------------+   |
|   | Kernel-Level TCP BBR Congestion Control                               |   |
|   |  - Optimized 16MB socket buffers for 92ms RTT latency paths           |   |
|   +-----------------------------------------------------------------------+   |
|                                   |                                           |
|   +-----------------------------------------------------------------------+   |
|   | Ingress Layer (wg-easy / Xray Core)                                   |   |
|   |  - WireGuard: ChaCha20-Poly1305 symmetric crypto                      |   |
|   |  - VLESS Reality: Real TLS 1.3 handshake against target SNI           |   |
|   |  - Admin Web UI: 127.0.0.1:51821 (Loopback only via SSH tunnel)       |   |
|   +-----------------------------------------------------------------------+   |
|            |                                           |                      |
|            | [Internal DNS Query]                      | [Internet Traffic]   |
|            v                                           v                      |
|   +-----------------------------------+   +-------------------------------+   |
|   | AdGuard Home (172.28.0.10:53)     |   | NAT Masquerade (Public IP)    |   |
|   | - 1.1M Rules / Anti-Gambling Sink |   | - Masked ISP Client Identity  |   |
|   +-----------------------------------+   +-------------------------------+   |
+-------------------------------------------------------------------------------+
```

---

## Empirical Deep Packet Inspection (DPI) Case Study

During operational verification across regional telecom providers (Central Asian ISPs with Deep Packet Inspection / TSPU), standard WireGuard exhibited immediate connection degradation:

### Packet Capture Analysis:
```text
12:05:13.360  Client -> Server   148B  [Handshake Initiation]
12:05:13.361  Server -> Client    92B  [Handshake Response] - Handshake Succeeded!
12:05:13.456  Client -> Server   8 Data Packets
12:05:13.458  Server -> Client   224B  Response Dispatched
12:05:28.871  Server -> Client   148B  No Answer (Drop)
12:05:33.991  Server -> Client   148B  No Answer (Drop) -> 92% packet drop rate
```

* **Root Cause:** Regional DPI systems detect the immutable 148-byte initiation and 92-byte response packet lengths of plain WireGuard, automatically dropping subsequent UDP traffic after ~98ms.
* **Mitigation:** Deployed **VLESS with XTLS Reality (Xray)** on port `2053`. Outbound sessions emulate legitimate TLS 1.3 handshakes directly with `www.microsoft.com`, returning authentic Microsoft certificates and rendering the VPN indistinguishable from regular enterprise HTTPS traffic.

---

## Performance Optimizations

1. **Google TCP BBR:**
   * Switched host congestion control from default `cubic` to `bbr`.
   * Compensates for packet drops over the 92ms path from Tashkent to Frankfurt, maximizing single-thread throughput.
2. **TCP Socket Buffer Scaling:**
   * Increased socket buffer allocations from 4MB to 16MB (`net.ipv4.tcp_rmem` / `net.ipv4.tcp_wmem`) to fully satisfy the Bandwidth-Delay Product (BDP) on 300 Mbps connections.

---

## Client Connection Guide

### Method A: Anti-Censorship Client (Hiddify — Recommended)
Works across Android, iOS, Windows, macOS, and Linux.

1. Install **Hiddify** from Google Play, App Store, or GitHub releases.
2. Copy your assigned `vless://...` configuration link.
3. In Hiddify, tap **Add from Clipboard** and connect.

#### ⚠️ Permanent Coexistence with Android Private DNS (Zero Conflicts)
If you run **Project 2: Personal Secure Gateway (Private DNS / DoT)** on Android, a hairpin routing loop occurs when the VPN tries to route DoT queries to the server's own public IP through the tunnel.

To keep your Private DNS active 24/7 without manual toggling:
1. Open **Hiddify** ➔ **Settings** ➔ **Routing**.
2. Enable **Android Services** (`↗ Напрямую: Службы Android`).
3. Tap **+** to add a Custom Direct Rule:
   * **Action:** `Direct` (`Напрямую`)
   * **Domain Suffix:** `dns.davlatyarov.uz` *(or `davlatyarov.uz`)*
   * **Destination IP CIDR:** `<SERVER_IP>/32`
4. Tap **✓ (Save)**.
Your phone's Private DNS and the VPN tunnel now coexist permanently without any routing loops.

---

### Method B: Native WireGuard Client
For environments with unrestricted UDP routing:

1. Open an SSH port forward on your laptop:
   ```bash
   ssh -L 51821:127.0.0.1:51821 root@<SERVER_IP>
   ```
2. Open `http://localhost:51821` in your browser.
3. Generate a client profile and scan the QR code with the official WireGuard app.

---

## Project Structure

```
personal-wireguard-vpn/
├── docker-compose.yml     # Hardened container manifest (gateway bridge network)
├── deploy.sh              # Automated deployment with secure password generation
├── verify.sh              # Multi-point health check & port diagnostic utility
├── .env.example           # Environment template with masked placeholders
├── wg/                    # Generated cryptographic configurations (gitignored)
└── README.md              # Engineering documentation & DPI case study
```

---

## Author
* **Muhammadqodir Davlatyorov** — Cybersecurity Researcher & Network Security Enthusiast.
* GitHub: [@Davlatyarov](https://github.com/Davlatyarov)
