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
            -e "s|\${PRIMARY_DOMAIN}|$PRIMARY_DOMAIN|g" \
            "$CAMP_TEMPLATE" > "$CAMP_CONF"
    else
        echo "⚠️  Template file not found: $CAMP_TEMPLATE (Skipping CampStation)"
    fi
else
    echo "ℹ️  CAMPSTATION_DOMAIN not set in .env (Skipping CampStation)"
fi

# -----------------------------------------------------------------------------
# Glamping Configuration (New)
# -----------------------------------------------------------------------------
GLAMPING_CONF="./nginx/conf.d/glamping.conf"
GLAMPING_TEMPLATE="${GLAMPING_CONF}.template"

if [ -n "$GLAMPING_DOMAIN" ]; then
    if [ -f "$GLAMPING_TEMPLATE" ]; then
        echo "🔧 Generating Glamping Nginx config..."
        sed -e "s|\${GLAMPING_DOMAIN}|$GLAMPING_DOMAIN|g" \
            -e "s|\${PRIMARY_DOMAIN}|$PRIMARY_DOMAIN|g" \
            "$GLAMPING_TEMPLATE" > "$GLAMPING_CONF"
    else
        echo "⚠️  Template file not found: $GLAMPING_TEMPLATE (Skipping Glamping)"
    fi
else
    echo "ℹ️  GLAMPING_DOMAIN not set in .env (Skipping Glamping)"
fi

# -----------------------------------------------------------------------------
# NMGSOFT Configuration (New)
# -----------------------------------------------------------------------------
NMGSOFT_CONF="./nginx/conf.d/nmgsoft.conf"
NMGSOFT_TEMPLATE="${NMGSOFT_CONF}.template"

if [ -n "$NMGSOFT_DOMAIN" ]; then
    if [ -f "$NMGSOFT_TEMPLATE" ]; then
        echo "🔧 Generating NMGSOFT Nginx config..."
        sed -e "s|\${NMGSOFT_DOMAIN}|$NMGSOFT_DOMAIN|g" \
            -e "s|\${PRIMARY_DOMAIN}|$PRIMARY_DOMAIN|g" \
            "$NMGSOFT_TEMPLATE" > "$NMGSOFT_CONF"
    else
        echo "⚠️  Template file not found: $NMGSOFT_TEMPLATE (Skipping NMGSOFT)"
    fi
else
    echo "ℹ️  NMGSOFT_DOMAIN not set in .env (Skipping NMGSOFT)"
fi

# -----------------------------------------------------------------------------
# TeleMarketing Configuration
# -----------------------------------------------------------------------------
TELEMARKETING_CONF="./nginx/conf.d/telemarketing.conf"
TELEMARKETING_TEMPLATE="${TELEMARKETING_CONF}.template"

if [ -n "$TELEMARKETING_DOMAIN" ]; then
    if [ -f "$TELEMARKETING_TEMPLATE" ]; then
        echo "🔧 Generating TeleMarketing Nginx config..."
        sed -e "s|\${TELEMARKETING_DOMAIN}|$TELEMARKETING_DOMAIN|g" \
            -e "s|\${PRIMARY_DOMAIN}|$PRIMARY_DOMAIN|g" \
            "$TELEMARKETING_TEMPLATE" > "$TELEMARKETING_CONF"
    else
        echo "⚠️  Template file not found: $TELEMARKETING_TEMPLATE (Skipping TeleMarketing)"
    fi
else
    echo "ℹ️  TELEMARKETING_DOMAIN not set in .env (Skipping TeleMarketing)"
fi


echo "🔄 Reloading Nginx..."
docker compose exec nginx nginx -s reload

echo "✅ Done! Nginx configuration updated."
