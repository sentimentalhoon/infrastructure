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
NGINX_CONF="./nginx/conf.d/psmo-community.conf"
NGINX_CONF_BAK="./nginx/conf.d/psmo-community.conf.bak"

# 1. Backup existing config and create HTTP-only temp config
echo "📝 Switching to temporary Nginx configuration..."
# Backup only if not already backed up
# Backup only if not already backed up AND original exists
if [ ! -f $NGINX_CONF_BAK ] && [ -f $NGINX_CONF ]; then
    cp $NGINX_CONF $NGINX_CONF_BAK
fi

# Create temp config (HTTP only, no SSL)
cat > $NGINX_CONF <<EOF
server {
    listen 80;
    server_name $DOMAIN_NAME;
    
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
    echo "❌ Certbot failed! Restoring original config..."
    if [ -f $NGINX_CONF_BAK ]; then
        mv $NGINX_CONF_BAK $NGINX_CONF
    else
        rm $NGINX_CONF
    fi
    exit 1
else
    echo "✅ Certificate obtained successfully!"
    echo "♻️  Restoring and updating Nginx configuration..."
    
    # Generate Config from Template
    echo "🔧 Generating Nginx configuration from template..."
    
    # Check if template exists
    if [ ! -f "${NGINX_CONF}.template" ]; then
        echo "❌ Template file not found: ${NGINX_CONF}.template"
        exit 1
    fi
    
    # Read template and substitute variables
    # We use sed for simple substitution to avoid installing gettext (envsubst)
    # 1. Replace ${DOMAIN_NAME}
    # 2. Replace ${PRIMARY_DOMAIN}
    sed -e "s|\${DOMAIN_NAME}|$DOMAIN_NAME|g" \
        -e "s|\${PRIMARY_DOMAIN}|$PRIMARY_DOMAIN|g" \
        "${NGINX_CONF}.template" > "$NGINX_CONF"
        
    echo "✅ Configuration generated for domains: $DOMAIN_NAME"
fi

# 5. Restart Nginx
echo "🔄 Restarting Nginx with SSL support..."
docker compose restart nginx

echo ""
echo "✅ SSL Setup Completed Successfully!"
echo "   Your sites should now be accessible via HTTPS."
