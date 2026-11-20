# High-Throughput WireGuard VPN Gateway

[![WireGuard](https://img.shields.io/badge/WireGuard-Kernel--Mode-88171A?logo=wireguard&logoColor=white)](https://www.wireguard.com/)
[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![Security](https://img.shields.io/badge/Security-ChaCha20--Poly1305-green.svg)](https://github.com/Davlatyarov/personal-wireguard-vpn)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A production-ready, hardened **Personal WireGuard VPN Gateway** with automated client provisioning (`wg-easy`) and loopback admin management. Engineered for zero-trust traffic tunneling, low-latency encryption, and complete isolation on shared Linux servers (compatible alongside HestiaCP, Nginx, Apache, and MySQL).

Integrated with **Project 2: Personal Secure Gateway** via an isolated Docker bridge network (`gateway`: `172.28.0.0/24`) for automated threat sinkholing and ad-blocking over VPN.

Developed by **Muhammadqodir Davlatyorov** (BSc Cybersecurity Student at International Digital University / University of Wolverhampton programme).

---

## Architecture Overview

```
 [ Android / iOS / Windows / macOS Client ]
                     |
                     | [Full-Tunnel WireGuard: ChaCha20-Poly1305]
                     | UDP Port 51820
                     v
+-------------------------------------------------------------------------------+
| Linux VPS Host (<SERVER_IP>)                                                  |
|                                                                               |
|   +-----------------------------------------------------------------------+   |
|   | Linux Kernel WireGuard Subsystem                                      |   |
|   |  - In-kernel fast cryptographic processing (ChaCha20-Poly1305)         |   |
|   |  - Zero user-space context switching overhead (<3% cryptographic loss) |   |
|   +-----------------------------------------------------------------------+   |
|                                   |                                           |
|   +-----------------------------------------------------------------------+   |
|   | wg-easy Container (Static IP: 172.28.0.20 on 'gateway' bridge)        |   |
|   |  - UDP 51820 -> WireGuard Data Plane                                  |   |
|   |  - TCP 127.0.0.1:51821 -> Admin UI (Loopback ONLY, Zero Public Web)  |   |
|   |  - Automated QR-code generation & profile distribution                |   |
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

## Key Security Features

1. **Kernel-Level Modern Cryptography:**
   * Utilizes state-of-the-art **ChaCha20** for symmetric encryption and **Poly1305** for authenticator checks (RFC 7539).
   * **Curve25519** ECDH key exchange for high security and 1-roundtrip handshakes.
   * Minimal cryptographic footprint: achieves **92–97% of bare-metal line rate** with under 95ms latency from Central Asia to Europe.

2. **Hardened Loopback Web Management:**
   * The client management web interface is bound strictly to `127.0.0.1:51821`.
   * **Zero public web exposure:** immune to automated web scanners, credential stuffing, and unauthenticated exploits.
   * Accessed securely over an encrypted SSH port tunnel:
     ```bash
     ssh -L 51821:127.0.0.1:51821 root@<SERVER_IP>
     ```

3. **Inter-Container Gateway Routing:**
   * Communicates directly with AdGuard Home over the internal Docker network `gateway` (`172.28.0.10:53`).
   * Ad-blocking, tracking protection, and betting sinkholing work out-of-the-box inside the VPN tunnel without exposing plain port 53 to the public internet.

4. **Shared Host Non-Invasive Isolation:**
   * Operates completely independently of shared hosting stacks (HestiaCP, cPanel).
   * Web ports (`80`, `443`), database (`3306`), and DNS (`53`, `853`) remain untouched.

5. **Full Tunnel Protection (0.0.0.0/0, ::/0):**
   * Forces all device traffic through the encrypted tunnel.
   * Masks client ISP identity and prevents local network eavesdropping on public Wi-Fi.

---

## Quick Deployment

### 1. Clone & Deploy on Server

```bash
git clone https://github.com/Davlatyarov/personal-wireguard-vpn.git
cd personal-wireguard-vpn
chmod +x deploy.sh verify.sh
./deploy.sh
```

### 2. Verify Stack Status

```bash
./verify.sh
```

---

## Client Connection Guide

### Step 1: Open SSH Tunnel on Your Laptop
Run the following in your local terminal:
```bash
ssh -L 51821:127.0.0.1:51821 root@<SERVER_IP>
```

### Step 2: Access Management Dashboard
Open your laptop browser at:
```text
http://localhost:51821
```
* Log in with username `admin` and the password generated during `./deploy.sh` (found in `.env`).

### Step 3: Connect Devices
* **Mobile (Android / iPhone):**
  1. Install the official **WireGuard** app from Google Play or App Store.
  2. In the web dashboard, click **+ New Client** (e.g. `Galaxy-S21`).
  3. Click the **QR Code** icon and scan it directly with the mobile app.
* **Desktop (Windows / macOS / Linux):**
  1. Click the **Download** button to save the `.conf` profile.
  2. Import the file into the official WireGuard desktop client.
  3. Click **Activate**.

---

## Project Structure

```
personal-wireguard-vpn/
├── docker-compose.yml     # Hardened WireGuard container manifest (gateway network)
├── deploy.sh              # Automated deployment & secret provisioning script
├── verify.sh              # Health check and port diagnostic utility
├── .env.example           # Secure configuration template
├── wg/                    # Generated WireGuard configs & keys (gitignored)
└── README.md              # Engineering documentation
```

---

## Author
* **Muhammadqodir Davlatyarov** — Cybersecurity Researcher & Network Security Enthusiast.
* GitHub: [@Davlatyarov](https://github.com/Davlatyarov)
