#!/bin/bash

# =============================================================================
# Apply Nginx Configuration Script
# =============================================================================
# This script regenerates the Nginx configuration from the template and reloads Nginx.
# Use this when you have updated psmo-community.conf.template but don't need to renew certs.
# =============================================================================

# Ensure we are in the workspace directory (basic check)
if [ ! -f docker-compose.yml ]; then
    echo "❌ Error: docker-compose.yml not found!"
    echo "   Please run this script from the 'infrastructure' directory."
    exit 1
fi

if [ ! -f .env ]; then
    echo "❌ .env file missing!"
    exit 1
fi

# Load Environment Variables
set -a
source .env
set +a

if [ -z "$DOMAIN_NAME" ]; then
    echo "❌ DOMAIN_NAME is empty in .env"
    exit 1
fi

PRIMARY_DOMAIN=$(echo "$DOMAIN_NAME" | awk '{print $1}')

echo "=================================================="
echo "  Applying Nginx Configuration"
echo "  Domains: $DOMAIN_NAME"
echo "=================================================="


# -----------------------------------------------------------------------------
# PSMO Community Configuration
# -----------------------------------------------------------------------------
NGINX_CONF="./nginx/conf.d/psmo-community.conf"
TEMPLATE="${NGINX_CONF}.template"

if [ -f "$TEMPLATE" ]; then
    echo "🔧 Generating PSMO Community Nginx config..."
    sed -e "s|\${DOMAIN_NAME}|$DOMAIN_NAME|g" \
        -e "s|\${PRIMARY_DOMAIN}|$PRIMARY_DOMAIN|g" \
        "$TEMPLATE" > "$NGINX_CONF"
else
    echo "⚠️  Template file not found: $TEMPLATE (Skipping PSMO)"
fi

# -----------------------------------------------------------------------------
# CampStation Configuration
# -----------------------------------------------------------------------------
CAMP_CONF="./nginx/conf.d/campstation.conf"
CAMP_TEMPLATE="${CAMP_CONF}.template"

if [ -n "$CAMPSTATION_DOMAIN" ]; then
    if [ -f "$CAMP_TEMPLATE" ]; then
        echo "🔧 Generating CampStation Nginx config..."
        sed -e "s|\${CAMPSTATION_DOMAIN}|$CAMPSTATION_DOMAIN|g" \
            "$CAMP_TEMPLATE" > "$CAMP_CONF"
    else
        echo "⚠️  Template file not found: $CAMP_TEMPLATE (Skipping CampStation)"
    fi
else
    echo "ℹ️  CAMPSTATION_DOMAIN not set in .env (Skipping CampStation)"
fi

echo "🔄 Reloading Nginx..."
docker compose exec nginx nginx -s reload

echo "✅ Done! Nginx configuration updated."
