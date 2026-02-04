#!/bin/bash

# =============================================================================
# SSL Certificate Initialization Script
# =============================================================================
# This script handles the first-time SSL setup by:
# 1. Using a temporary HTTP-only Nginx config
# 2. Starting Nginx to allow Certbot validation
# 3. Generating certificates for all domains
# 4. Updating and restoring the production SSL config
# =============================================================================

# Ensure we are in the workspace directory (basic check)
if [ ! -f docker-compose.yml ]; then
    echo "❌ Error: docker-compose.yml not found!"
    echo "   Please run this script from the 'infrastructure' directory."
    exit 1
fi

if [ ! -f .env ]; then
    echo "❌ .env file missing! Please run ./setup-env.sh first."
    exit 1
fi

# Load Environment Variables safely
set -a
source .env
set +a

# Validate Variables
if [ -z "$DOMAIN_NAME" ]; then
    echo "❌ DOMAIN_NAME is empty in .env. Please re-run ./setup-env.sh"
    exit 1
fi
if [ -z "$CERTBOT_EMAIL" ]; then
    echo "❌ CERTBOT_EMAIL is empty in .env. Please re-run ./setup-env.sh"
    exit 1
fi

# Ensure test domain is not included in production SSL/Config


echo "=================================================="
echo "  SSL Certificate Setup"
echo "  Domains: $DOMAIN_NAME"
echo "=================================================="
echo ""

# Configuration Paths
TEMP_CONF="./nginx/conf.d/temp-setup.conf"

# 1. Clean up existing configs to prevent startup errors (conflicting SSL)
echo "🧹 Clearing existing Nginx configs (Templates will remain)..."
rm -f ./nginx/conf.d/*.conf

# Create temp config (HTTP only, no SSL) for ALL domains
echo "📝 Creating temporary HTTP-only configuration..."
cat > $TEMP_CONF <<EOF
server {
    listen 80;
    server_name $ALL_DOMAINS;
    
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    location / {
        return 301 https://\$host\$request_uri;
    }
}
EOF

# 2. Start Nginx (only)
echo "🚀 Starting Nginx..."
# Ensure nginx is down first to force reload config
docker compose stop nginx
docker compose rm -f nginx
docker compose up -d nginx

echo "⏳ Waiting for Nginx to start..."
sleep 10

# 3. Request Certificates
echo "🔐 Requesting SSL Certificates via Certbot..."

# Certbot domains: space to comma
CERTBOT_DOMAINS=$(echo "$DOMAIN_NAME" | tr ' ' ',')
# Primary domain (first one) for folder path
PRIMARY_DOMAIN=$(echo "$DOMAIN_NAME" | awk '{print $1}')

docker compose run --rm certbot certonly \
    --webroot \
    --webroot-path /var/www/certbot \
    -d "$CERTBOT_DOMAINS" \
    --email "$CERTBOT_EMAIL" \
    --agree-tos \
    --no-eff-email \
    --no-eff-email

CERTBOT_EXIT_CODE=$?

# 4. Restore and Update Config logic
if [ $CERTBOT_EXIT_CODE -ne 0 ]; then
    echo "❌ Certbot failed!"
    echo "   Removing temp config..."
    rm -f $TEMP_CONF
    echo "   You may need to run ./apply-nginx-config.sh to restore previous configs."
    exit 1
else
    echo "✅ Certificate obtained successfully!"
    echo "🧹 Removing temporary configuration..."
    rm -f $TEMP_CONF
    
    echo "♻️  Regenerating Nginx configuration..."
    
    # Run the apply script to generate all configs
    if [ -f "./apply-nginx-config.sh" ]; then
        chmod +x ./apply-nginx-config.sh
        ./apply-nginx-config.sh
    else
        echo "❌ apply-nginx-config.sh not found! Please run it manually."
    fi
     
    echo "✅ Configuration generated for domains: $ALL_DOMAINS"
fi

# 5. Restart Nginx
echo "🔄 Restarting Nginx with SSL support..."
docker compose restart nginx

echo ""
echo "✅ SSL Setup Completed Successfully!"
echo "   Your sites should now be accessible via HTTPS."
