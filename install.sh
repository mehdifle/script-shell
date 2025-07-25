#!/bin/bash

set -e

OLD_SERVER="socket.loobi.space"
SSH_USER="root"
OLD_SSH_PORT=3031
TMP_DIR="/tmp/outline_migration"

echo "🔧 تنظیم حالت غیر تعاملی برای نصب بسته‌ها..."
export DEBIAN_FRONTEND=noninteractive

# Prompt for SSH password
read -sp "لطفاً پسورد SSH برای $SSH_USER@$OLD_SERVER را وارد کنید: " SSH_PASSWORD
echo

mkdir -p "$TMP_DIR"

echo "⚙️ نصب SSHPASS..."
apt install sshpass
apt install rsync

echo "⚙️ نصب اولیه Outline Server..."
bash -c "$(curl -sS https://raw.githubusercontent.com/Jigsaw-Code/outline-server/master/src/server_manager/install_scripts/install_server.sh)"

echo "🛑 توقف موقت کانتینرهای Outline..."
docker stop shadowbox || true
docker stop watchtower || true
sleep 2

echo "📦 انتقال کامل تنظیمات از سرور قبلی با پورت $OLD_SSH_PORT..."
# Use sshpass to provide password for rsync over SSH
ssh -p 3031 root@socket.loobi.space
apt install rsync
exit
SSHPASS="$SSH_PASSWORD" rsync -avz -e 'sshpass -e ssh -o StrictHostKeyChecking=no -p 3031' root@socket.loobi.space:/opt/outline/ /opt/outline/

echo "🚀 راه‌اندازی مجدد Outline با تنظیمات قبلی..."
docker start shadowbox
docker start watchtower
sleep 3

API_URL=$(grep -oP 'https://\S+' /opt/outline/access.txt || true)

if curl -s --max-time 5 "$API_URL" >/dev/null 2>&1; then
  echo "🎉 Outline با موفقیت منتقل و راه‌اندازی شد."
  echo "🌐 API: $API_URL"
else
  echo "⚠️ سرور اجرا شد ولی اتصال به API برقرار نشد. لطفاً لاگ‌ها را بررسی کن:"
  docker logs shadowbox --tail 30
fi

echo "🔐 تغییر پورت SSH به 3031..."
SSH_CONF="/etc/ssh/sshd_config"
sed -i '/^#\?Port /d' "$SSH_CONF"
echo "Port 3031" >> "$SSH_CONF"

echo "♻️ ریستارت سرویس SSH..."
systemctl restart ssh

echo "✅ SSH حالا روی پورت 3031 در دسترس است. از دستور زیر برای اتصال استفاده کن:"
echo "   ssh -p 3031 ${SSH_USER}@<IP>"
