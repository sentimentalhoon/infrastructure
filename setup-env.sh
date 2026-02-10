#!/bin/bash

# =============================================================================
# Infrastructure Environment Setup Script (Gateway)
# =============================================================================
# Usage: ./setup-env.sh
# =============================================================================

set -e

echo "=================================================="
echo "  Infrastructure Gateway - Environment Setup"
echo "=================================================="
echo ""

# Check if .env already exists
if [ -f ".env" ]; then
    echo "⚠️  .env already exists!"
    read -p "Do you want to overwrite it? (yes/no): " -r
    echo
    if [[ ! $REPLY =~ ^[Yy]es$ ]]; then
        echo "❌ Setup cancelled."
        exit 1
    fi
fi

# -----------------------------------------------------------------------------
# 1. SSL / Domain Configuration
# -----------------------------------------------------------------------------
echo "🌐 Domain & SSL Configuration"
echo "   Enter domains separated by space (include ALL domains for all projects)."
echo "   Example: dool.co.kr www.dool.co.kr api.dool.co.kr"
read -p "Enter Domain(s): " DOMAIN_NAME

if [ -z "$DOMAIN_NAME" ]; then
    echo "❌ Domain is required!"
    exit 1
fi

read -p "Enter Email for SSL specificiation (Certbot): " CERTBOT_EMAIL

if [ -z "$CERTBOT_EMAIL" ]; then
    echo "❌ Email is required!"
    exit 1
fi

echo ""
echo "🏕️  CampStation Domain Configuration"
read -p "Enter CampStation Domain (optional): " CAMPSTATION_DOMAIN

echo ""
echo "⛺  Glamping Domain Configuration"
read -p "Enter Glamping Domain (optional): " GLAMPING_DOMAIN

echo ""
echo "🏢  NMGSOFT Domain Configuration"
read -p "Enter NMGSOFT Domain (optional): " NMGSOFT_DOMAIN


# -----------------------------------------------------------------------------
# 2. Write to .env
# -----------------------------------------------------------------------------
cat > .env << EOF
# =============================================================================
# Infrastructure Environment Variables
# =============================================================================
# Generated on: $(date)

# --- Domain & SSL ---
DOMAIN_NAME="${DOMAIN_NAME}"
CERTBOT_EMAIL="${CERTBOT_EMAIL}"

# --- Project Domains ---
CAMPSTATION_DOMAIN="${CAMPSTATION_DOMAIN}"
GLAMPING_DOMAIN="${GLAMPING_DOMAIN}"
NMGSOFT_DOMAIN="${NMGSOFT_DOMAIN}"

EOF

echo ""
echo "✅ .env file created successfully!"
echo ""
echo "🚀 Next Steps:"
echo "   1. ./init-ssl.sh  (If setting up SSL for the first time)"
echo "   2. docker compose up -d"
echo ""
