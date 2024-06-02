#!/bin/sh
#パッケージのアンインストール
sudo yum -y remove squid
sudo rm -f /etc/squid/squid.conf
sudo rm -f /etc/squid/.htpasswd
#パッケージのインストール
sudo yum -y install squid
sudo yum -y install httpd
sudo yum -y install expect
#ポート開放
sudo firewall-cmd --zone=public --add-port=3128/tcp --permanent
sudo firewall-cmd --reload
#認証用ユーザーの作成
ID="userid"
PW="userpass"
expect -c "
set timeout 20
spawn htpasswd -c /etc/squid/.htpasswd \"${ID}\"
expect \"password:\"
send \"${PW}\n\"
expect \"password:\"
send \"${PW}\n\"
expect \"$\"  exit 0" 
#プロキシサーバー経由での接続を隠蔽 
sudo sed -i -e '/http_access allow localhost manager/ a\forwarded_for off' /etc/squid/squid.conf
sudo sed -i -e '/http_access allow localhost manager/ a\request_header_access X-Forwarded-For deny all' /etc/squid/squid.conf
sudo sed -i -e '/http_access allow localhost manager/ a\request_header_access Via deny all' /etc/squid/squid.conf
sudo sed -i -e '/http_access allow localhost manager/ a\request_header_access Cache-Control deny all' /etc/squid/squid.conf
sudo sed -i -e '/http_access allow localhost manager/ a\no_cache deny all' /etc/squid/squid.conf
#Basic認証用の設定
sudo sed -i -e '/http_access allow localhost manager/ a\http_access allow password' /etc/squid/squid.conf
sudo sed -i -e '/http_access allow localhost manager/ a\acl password proxy_auth REQUIRED' /etc/squid/squid.conf
sudo sed -i -e '/http_access allow localhost manager/ a\auth_param basic program /usr/lib64/squid/basic_ncsa_auth /etc/squid/.htpasswd' /etc/squid/squid.conf
sudo sed -i -e '/http_access allow localhost manager/ a\auth_param basic children 5' /etc/squid/squid.conf
sudo sed -i -e '/http_access allow localhost manager/ a\auth_param basic realm Basic Authentication' /etc/squid/squid.conf
sudo sed -i -e '/http_access allow localhost manager/ a\auth_param basic credentialsttl 24 hours' /etc/squid/squid.conf
#サービス起動設定
sudo systemctl enable squid
sudo systemctl restart squid
sudo systemctl status squid.service
