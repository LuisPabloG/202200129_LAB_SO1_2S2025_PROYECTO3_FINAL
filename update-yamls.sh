#!/bin/bash

ZOT_IP="35.188.198.252"

echo "🔧 Updating YAML files with ZOT_IP: $ZOT_IP"

# Actualizar todos los deployments
find k8s/deployments -name "*.yaml" -type f -exec sed -i "s/<ZOT_IP>/${ZOT_IP}/g" {} +

echo "✅ YAML files updated!"
echo "📋 Updated files:"
grep -r "35.188.198.252" k8s/deployments/
