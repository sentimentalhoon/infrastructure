# Infrastructure Separation Walkthrough

We have successfully separated the Nginx reverse proxy and SSL management into a dedicated infrastructure project.

## Changes Made

### 1. New Infrastructure Project (`d:\WORKSPACE\infrastructure`)
*   **Gateway**: Created `docker-compose.yml` hosting only Nginx and Certbot.
*   **Network**: Configured to use external network `web-proxy-net`.
*   **Scripts**: Migrated `init-ssl.sh` and `renew-cert.sh` to this folder and updated them to point to the new docker-compose file.
*   **Config**: Nginx configurations are now managed here.

### 2. PSMO Community Updates (`d:\WORKSPACE\psmo_community`)
*   **Docker Compose**: Removed `nginx` and `certbot` services.
*   **Network**: Added `web-proxy-net` (external) and connected `psmo-backend`, `psmo-frontend`, and `psmo-minio` to it.

## How to Deploy

### Step 1: Start Infrastructure (Gateway)
```bash
cd d:\WORKSPACE\infrastructure
# Ensure network exists
docker network create web-proxy-net
# Start Gateway
docker compose up -d
```

### Step 2: Start PSMO Application
```bash
cd d:\WORKSPACE\psmo_community
# Start Application (will join existing network)
docker compose -f docker-compose.prod.yml up -d
```
