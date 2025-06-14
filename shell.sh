#!/bin/bash

apt update && apt upgrade -y
apt install curl socat -y
apt install cron -y
apt install nginx -y
systemctl enable nginx
curl https://get.acme.sh | sh
~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
~/.acme.sh/acme.sh --register-account -m admin@loobi.space
service nginx stop
~/.acme.sh/acme.sh --issue -d socket.loobi.space --standalone
~/.acme.sh/acme.sh --installcert -d socket.loobi.space --key-file /root/private.key --fullchain-file /root/cert.crt
service nginx start
bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
