#!/bin/sh
yum -y install squid
yum -y install httpd
yum -y install expect
yum -y update openssl
PW="userpass"
expect -c "
set timeout 20
spawn htpasswd -c /etc/squid/.htpasswd userid
expect \"password:\"
send \"${PW}\n\"
expect \"password:\"
send \"${PW}\n\"
expect \"$\"  exit 0" 
sed -i -e '30i auth_param basic program /usr/lib64/squid/ncsa_auth /etc/squid/.htpasswd\nauth_param basic children 5\nauth_param basic realm Squnewid Basic Authentication\nauth_param basic credentialsttl 24 hours\nacl password proxy_auth REQUIRED\nhttp_access allow password\n\nforwarded_for off\nrequest_header_access Referer deny all\nrequest_header_access X-Forwarded-For deny all\nrequest_header_access Via deny all\nrequest_header_access Cache-Control deny all\nvisible_hostname unknown\nno_cache deny all\n' /etc/squid/squid.conf
sed -i 's/3128/userport/g' /etc/squid/squid.conf
firewall-cmd --zone=public --add-port=userport/tcp --permanent
firewall-cmd --reload
/etc/rc.d/init.d/iptables stop
chkconfig squid on
service squid start
rm -f script.sh