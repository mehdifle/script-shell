#!/bin/bash

set -e

OLD_SERVER="web.loobi.space"
SSH_USER="root"
TMP_DIR="/tmp/outline_migration"

echo "🔧 نصب ابزارهای مورد نیاز..."
apt update -y
apt install -y rsync curl jq docker.io docker-compose

mkdir -p "$TMP_DIR"

# -----------------------------
# نصب اولیه Outline Server
# -----------------------------
echo "⚙️ نصب اولیه Outline Server..."
bash -c "$(curl -sS https://raw.githubusercontent.com/Jigsaw-Code/outline-server/master/src/server_manager/install_scripts/install_server.sh)" > "$TMP_DIR/install.log" 2>&1

# -----------------------------
# متوقف کردن کانتینرها
# -----------------------------
echo "🛑 توقف موقت کانتینرهای Outline..."
docker stop shadowbox || true
docker stop watchtower || true
sleep 2

# -----------------------------
# جایگزینی کامل پوشه /opt/outline
# -----------------------------
echo "📦 انتقال کامل تنظیمات از سرور قبلی..."
rsync -avz -e ssh "${SSH_USER}@${OLD_SERVER}:/opt/outline/" /opt/outline/

# -----------------------------
# راه‌اندازی مجدد Outline
# -----------------------------
echo "🚀 راه‌اندازی مجدد Outline با تنظیمات قدیمی..."
docker start shadowbox
docker start watchtower
sleep 3

# -----------------------------
# بررسی سلامت
# -----------------------------
API_URL=$(grep -oP 'https://\S+' /opt/outline/access.txt || true)

if curl -s --max-time 5 "$API_URL" >/dev/null 2>&1; then
  echo "🎉 Outline با موفقیت منتقل و راه‌اندازی شد."
  echo "🌐 API: $API_URL"
else
  echo "⚠️ سرور اجرا شد ولی اتصال به API برقرار نشد. لطفاً لاگ‌ها را بررسی کن:"
  docker logs shadowbox --tail 30
fi
