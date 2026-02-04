#!/bin/bash

# =============================================================================
# SSL Certificate Renewal Script
# =============================================================================
# Run this script periodically (e.g., via Cron) to renew Let's Encrypt certificates.
# It only renews certificates that are close to expiration (within 30 days).
# =============================================================================

# Ensure we are in the workspace directory containing docker-compose.prod.yml
cd "$(dirname "$0")"

if [ ! -f docker-compose.prod.yml ]; then
    echo "❌ Error: docker-compose.prod.yml not found in $(pwd)"
    exit 1
fi

echo "🔄 [$(date)] Starting SSL Renewal Check..."

# 1. Run Certbot Renewal
# "renew" command only affects certificates within 30 days of expiry
docker compose -f docker-compose.prod.yml run --rm certbot renew

CERTBOT_EXIT_CODE=$?

if [ $CERTBOT_EXIT_CODE -eq 0 ]; then
    echo "✅ [$(date)] Certbot renewal check finished."
    
    # 2. Reload Nginx to load new certificates
    # We use 'reload' instead of 'restart' for zero downtime
    echo "🔄 Reloading Nginx to apply changes..."
    docker compose -f docker-compose.prod.yml exec nginx nginx -s reload
else
    echo "❌ [$(date)] Certbot renewal failed!"
    exit 1
fi
