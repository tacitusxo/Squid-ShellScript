#!/bin/sh
#Failed to fetchエラーになる場合の対応
sudo rm -rf /var/lib/apt/lists/*
sudo apt-get update
#パッケージのアンインストール
sudo apt remove squid -y
sudo rm -f /etc/squid/squid.conf
#パッケージのインストール
sudo apt install squid -y
#ポート開放
sudo ufw allow 3128
#認証用ユーザーの作成
sudo sh -c "echo -n 'userid:$(openssl passwd -apr1 userpass)\n' >> /etc/squid/.htpasswd"
#プロキシサーバー経由での接続を隠蔽 
sudo sed -i -e '/http_access allow localhost manager/ i\forwarded_for off' /etc/squid/squid.conf
sudo sed -i -e '/http_access allow localhost manager/ i\request_header_access X-Forwarded-For deny all' /etc/squid/squid.conf
sudo sed -i -e '/http_access allow localhost manager/ i\request_header_access Via deny all' /etc/squid/squid.conf
sudo sed -i -e '/http_access allow localhost manager/ i\request_header_access Cache-Control deny all' /etc/squid/squid.conf
sudo sed -i -e '/http_access allow localhost manager/ i\no_cache deny all' /etc/squid/squid.conf
#Basic認証用の設定
sudo sed -i -e '/http_access allow localhost manager/ i\auth_param basic program /usr/lib/squid/basic_ncsa_auth /etc/squid/.htpasswd' /etc/squid/squid.conf
sudo sed -i -e '/http_access allow localhost manager/ i\auth_param basic children 5' /etc/squid/squid.conf
sudo sed -i -e '/http_access allow localhost manager/ i\auth_param basic realm Basic Authentication' /etc/squid/squid.conf
sudo sed -i -e '/http_access allow localhost manager/ i\auth_param basic credentialsttl 24 hours' /etc/squid/squid.conf
sudo sed -i -e '/http_access allow localhost manager/ i\acl password proxy_auth REQUIRED' /etc/squid/squid.conf
sudo sed -i -e '/http_access allow localhost manager/ i\http_access allow password' /etc/squid/squid.conf
#サービス起動設定
sudo systemctl enable squid
sudo systemctl restart squid
sudo systemctl status squid.service