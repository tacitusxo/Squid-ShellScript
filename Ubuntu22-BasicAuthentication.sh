#!/bin/sh
#パッケージのインストール
sudo apt install squid -y
sudo apt install expect -y
sudo apt install apache2-utils -y
#ポート開放
sudo ufw allow 3128
#認証用ユーザーの作成
ID="userid"
PW="userpass"
expect -c "
set timeout 20
spawn htpasswd -c /etc/squid/.htpasswd \"${ID}\n\"
expect \"password:\"
send \"${PW}\n\"
expect \"password:\"
send \"${PW}\n\"
expect \"$\"  exit 0" 
#プロキシサーバー経由での接続を隠蔽 
sudo sed -i -e '/acl CONNECT method CONNECT/ a\forwarded_for off' /etc/squid/squid.conf
sudo sed -i -e '/acl CONNECT method CONNECT/ a\request_header_access X-Forwarded-For deny all' /etc/squid/squid.conf
sudo sed -i -e '/acl CONNECT method CONNECT/ a\request_header_access Via deny all' /etc/squid/squid.conf
sudo sed -i -e '/acl CONNECT method CONNECT/ a\request_header_access Cache-Control deny all' /etc/squid/squid.conf
sudo sed -i -e '/acl CONNECT method CONNECT/ a\no_cache deny all' /etc/squid/squid.conf
#Basic認証用の設定
sudo sed -i -e '/acl CONNECT method CONNECT/ a\http_access allow password' /etc/squid/squid.conf
sudo sed -i -e '/acl CONNECT method CONNECT/ a\acl password proxy_auth REQUIRED' /etc/squid/squid.conf
sudo sed -i -e '/acl CONNECT method CONNECT/ a\auth_param basic program /usr/lib/squid/basic_ncsa_auth /etc/squid/.htpasswd' /etc/squid/squid.conf
sudo sed -i -e '/acl CONNECT method CONNECT/ a\auth_param basic children 5' /etc/squid/squid.conf
sudo sed -i -e '/acl CONNECT method CONNECT/ a\auth_param basic realm Basic Authentication' /etc/squid/squid.conf
sudo sed -i -e '/acl CONNECT method CONNECT/ a\auth_param basic credentialsttl 24 hours' /etc/squid/squid.conf
#サービス起動設定
sudo systemctl enable squid
sudo systemctl start squid
sudo systemctl status squid.service