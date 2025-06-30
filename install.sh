#!/bin/bash

set -e

OLD_SERVER="web.loobi.space"
SSH_USER="root"
OLD_SSH_PORT=3031
TMP_DIR="/tmp/outline_migration"

echo "🔧 نصب ابزارهای مورد نیاز..."
apt update -y
apt install -y rsync curl jq docker.io docker-compose openssh-server

mkdir -p "$TMP_DIR"

# -----------------------------
# نصب اولیه Outline Server
# -----------------------------
echo "⚙️ نصب اولیه Outline Server..."
bash -c "$(curl -sS https://raw.githubusercontent.com/Jigsaw-Code/outline-server/master/src/server_manager/install_scripts/install_server.sh)" > "$TMP_DIR/install.log" 2>&1

# -----------------------------
# توقف کانتینرهای قبلی (در صورت وجود)
# -----------------------------
echo "🛑 توقف موقت کانتینرهای Outline..."
docker stop shadowbox || true
docker stop watchtower || true
sleep 2

# -----------------------------
# جایگزینی کامل پوشه /opt/outline
# -----------------------------
echo "📦 انتقال کامل تنظیمات از سرور قبلی با پورت $OLD_SSH_PORT..."
rsync -avz -e "ssh -p $OLD_SSH_PORT" "${SSH_USER}@${OLD_SERVER}:/opt/outline/" /opt/outline/

# -----------------------------
# راه‌اندازی مجدد Outline
# -----------------------------
echo "🚀 راه‌اندازی مجدد Outline با تنظیمات قبلی..."
docker start shadowbox
docker start watchtower
sleep 3

# -----------------------------
# بررسی وضعیت API
# -----------------------------
API_URL=$(grep -oP 'https://\S+' /opt/outline/access.txt || true)

if curl -s --max-time 5 "$API_URL" >/dev/null 2>&1; then
  echo "🎉 Outline با موفقیت منتقل و راه‌اندازی شد."
  echo "🌐 API: $API_URL"
else
  echo "⚠️ سرور اجرا شد ولی اتصال به API برقرار نشد. لطفاً لاگ‌ها را بررسی کن:"
  docker logs shadowbox --tail 30
fi

# -----------------------------
# تغییر پورت SSH به 3031
# -----------------------------
echo "🔐 تغییر پورت SSH به 3031..."

SSH_CONF="/etc/ssh/sshd_config"

# حذف خط‌های قدیمی مربوط به Port
sed -i '/^#\?Port /d' "$SSH_CONF"

# اضافه‌کردن پورت جدید
echo "Port 3031" >> "$SSH_CONF"

# ریستارت SSH
echo "♻️ ریستارت سرویس SSH..."
systemctl restart ssh

echo "✅ SSH حالا روی پورت 3031 در دسترس است. از دستور زیر برای اتصال استفاده کن:"
echo "   ssh -p 3031 root@<IP>"
