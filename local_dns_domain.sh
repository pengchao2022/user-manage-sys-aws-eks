#!/bin/bash

# setup-local-dns.sh
set -e

echo "🔧 Setting up local DNS for ALB testing..."

# 获取 Kubernetes 上下文
CLUSTER_NAME="${1:-user-registration-staging}"
NAMESPACE="${2:-user-register}"

# 配置 kubectl
aws eks update-kubeconfig --region us-east-1 --name $CLUSTER_NAME

# 等待 ALB 创建
echo "⏳ Waiting for ALB to be ready..."
for i in {1..30}; do
    ALB_HOSTNAME=$(kubectl get ingress user-registration-app-ingress -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
    
    if [ -n "$ALB_HOSTNAME" ]; then
        echo "✅ ALB Hostname: $ALB_HOSTNAME"
        break
    fi
    
    echo "⏳ Waiting... ($i/30)"
    sleep 10
done

if [ -z "$ALB_HOSTNAME" ]; then
    echo "❌ Failed to get ALB hostname"
    exit 1
fi

# 获取 ALB IP
ALB_IP=$(dig +short $ALB_HOSTNAME | head -1)
echo "🌐 ALB IP: $ALB_IP"

# 备份原有 hosts 文件
sudo cp /etc/hosts /etc/hosts.backup.$(date +%Y%m%d%H%M%S)

# 移除旧的条目
sudo sed -i '' '/local-app\.local/d' /etc/hosts
sudo sed -i '' '/staging-app\.local/d' /etc/hosts

# 添加新的条目
echo "📝 Updating /etc/hosts..."
echo "$ALB_IP   local-app.local" | sudo tee -a /etc/hosts
echo "$ALB_IP   staging-app.local" | sudo tee -a /etc/hosts

echo ""
echo "🎉 Local DNS setup completed!"
echo "🌐 You can now access:"
echo "   - http://local-app.local"
echo "   - http://staging-app.local"
echo ""
echo "🔗 Direct ALB URL: http://$ALB_HOSTNAME"
echo "📋 Hosts file updated at: /etc/hosts"
