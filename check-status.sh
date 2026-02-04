#!/bin/bash
echo "=================================================="
echo "  System Diagnostics"
echo "=================================================="

echo "1. Docker Container Status:"
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "nginx|campstation|psmo"
echo ""

echo "2. Nginx Gateway Logs (Last 50 lines):"
echo "--------------------------------------------------"
docker logs --tail 50 nginx-gateway
echo "--------------------------------------------------"
echo ""

echo "3. Temporary Config File Content:"
echo "--------------------------------------------------"
if [ -f "./nginx/conf.d/temp-setup.conf" ]; then
    cat ./nginx/conf.d/temp-setup.conf
else
    echo "❌ temp-setup.conf not found!"
fi
echo "--------------------------------------------------"
echo ""

echo "4. Port Usage (80/443):"
sudo lsof -i :80
sudo lsof -i :443
