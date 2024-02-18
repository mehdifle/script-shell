#!/bin/bash

apt update && apt upgrade -y
apt install curl socat -y
apt install cron
curl https://get.acme.sh | sh
~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
~/.acme.sh/acme.sh --register-account -m admin@loobi.biz
~/.acme.sh/acme.sh --issue -d pwa.loobi.biz --standalone
~/.acme.sh/acme.sh --installcert -d pwa.loobi.biz --key-file /root/private.key --fullchain-file /root/cert.crt
bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
