#!/bin/bash

#Requirement
if [ ! -e /usr/bin/curl ]; then
   yum -y update && yum -y upgrade
   yum -y install curl
fi

# initialisasi var
OS=`uname -m`;
MYIP=$(curl -4 icanhazip.com)
if [ $MYIP = "" ]; then
   MYIP=`ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0'`;
fi
echo $MYIP
MYIP2="s/xxxxxxxxx/$MYIP/g";


# go to root
cd

# set locale
sed -i 's/AcceptEnv/#AcceptEnv/g' /etc/ssh/sshd_config
service sshd restart

# disable ipv6
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
sed -i '$ i\echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.local
sed -i '$ i\echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.d/rc.local

#Add DNS Server ipv4
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 8.8.4.4" >> /etc/resolv.conf
sed -i '$ i\echo "nameserver 8.8.8.8" > /etc/resolv.conf' /etc/rc.local
sed -i '$ i\echo "nameserver 8.8.4.4" >> /etc/resolv.conf' /etc/rc.local
sed -i '$ i\echo "nameserver 8.8.8.8" > /etc/resolv.conf' /etc/rc.d/rc.local
sed -i '$ i\echo "nameserver 8.8.4.4" >> /etc/resolv.conf' /etc/rc.d/rc.local



# install wget and curl
yum -y install wget curl

# Mirror Repo
wget http://script.hostingtermurah.net/repo/autoscript/centos6/epel-release-6-8.noarch.rpm
wget http://script.hostingtermurah.net/repo/autoscript/centos6/remi-release-6.rpm
rpm -Uvh epel-release-6-8.noarch.rpm
rpm -Uvh remi-release-6.rpm
if [ "$OS" == "x86_64" ]; then
wget http://script.hostingtermurah.net/repo/autoscript/centos6/rpmforge-release-0.5.3-1.el6.rf.x86_64.rpm
rpm -Uvh rpmforge-release-0.5.3-1.el6.rf.x86_64.rpm
# else
wget http://script.hostingtermurah.net/repo/autoscript/centos6/rpmforge-release-0.5.3-1.el6.rf.i686.rpm
rpm -Uvh rpmforge-release-0.5.3-1.el6.rf.i686.rpm
fi
sed -i -e "/^\[remi\]/,/^\[.*\]/ s|^\(enabled[ \t]*=[ \t]*0\\)|enabled=1|" /etc/yum.repos.d/remi.repo
rm -f *.rpm

# remove unused
yum -y remove sendmail;
yum -y remove httpd;
yum -y remove cyrus-sasl

# update
yum -y update

# install webserver
yum -y install nginx php-fpm php-cli
service nginx restart
service php-fpm restart
chkconfig nginx on
chkconfig php-fpm on

# install essential package
yum -y install rrdtool screen iftop htop nmap bc nethogs openvpn vnstat ngrep mtr git zsh mrtg unrar rsyslog rkhunter mrtg net-snmp net-snmp-utils expect nano bind-utils
yum -y groupinstall 'Development Tools'
yum -y install cmake

yum -y --enablerepo=rpmforge install axel sslh ptunnel unrar

# matiin exim
service exim stop
chkconfig exim off

# setting vnstat
vnstat -u -i venet0
echo "MAILTO=root" > /etc/cron.d/vnstat
echo "*/5 * * * * root /usr/sbin/vnstat.cron" >> /etc/cron.d/vnstat
sed -i 's/eth0/venet0/g' /etc/sysconfig/vnstat
service vnstat restart
chkconfig vnstat on

# install screenfetch
cd
wget -O /usr/bin/screenfetch "http://script.hostingtermurah.net/repo/screenfetch"
chmod +x /usr/bin/screenfetch
echo "clear" >> .bash_profile
echo "screenfetch" >> .bash_profile

# nginx
apt-get -y install nginx php5-fpm php5-cli libexpat1-dev libxml-parser-perl
rm /etc/nginx/sites-enabled/default
rm /etc/nginx/sites-available/default
wget -O /etc/nginx/nginx.conf "http://files.rzvpn.net/rz/nginx.conf"
mkdir -p /home/vps/public_html
echo "<pre>Setup by meow | telegram @nswircz | whatsapp +60176218006</pre>" > /home/vps/public_html/index.php
echo "<?php phpinfo(); ?>" > /home/vps/public_html/info.php
wget -O /etc/nginx/conf.d/vps.conf "http://files.rzvpn.net/rz/vps.conf"
sed -i 's/listen = \/var\/run\/php5-fpm.sock/listen = 127.0.0.1:9000/g' /etc/php5/fpm/pool.d/www.conf

#install PPTP
cd
yum -y install pptpd
cat > /etc/ppp/pptpd-options <<END
name pptpd
refuse-pap
refuse-chap
refuse-mschap
require-mschap-v2
require-mppe-128
ms-dns 8.8.8.8
ms-dns 8.8.4.4
proxyarp
nodefaultroute
lock
nobsdcomp
END
echo "option /etc/ppp/pptpd-options" > /etc/pptpd.conf
echo "logwtmp" >> /etc/pptpd.conf
echo "localip 10.1.0.1" >> /etc/pptpd.conf
echo "remoteip 10.1.0.5-100" >> /etc/pptpd.conf
PASS2=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 15 | head -n 1`;
cat >> /etc/ppp/ip-up <<END
ifconfig ppp0 mtu 1400
END
mkdir /var/lib/premium-script
/etc/init.d/pptpd restart
chkconfig pptpd on

# install badvpn
wget -O /usr/bin/badvpn-udpgw "http://script.hostingtermurah.net/repo/badvpn-udpgw"
if [ "$OS" == "x86_64" ]; then
  wget -O /usr/bin/badvpn-udpgw "http://script.hostingtermurah.net/repo/badvpn-udpgw64"
fi
sed -i '$ i\screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300' /etc/rc.local
sed -i '$ i\screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300' /etc/rc.d/rc.local
chmod +x /usr/bin/badvpn-udpgw
screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300

# install mrtg
cd /etc/snmp/
wget -O /etc/snmp/snmpd.conf "http://script.hostingtermurah.net/repo/snmpd.conf"
wget -O /root/mrtg-mem.sh "http://script.hostingtermurah.net/repo/mrtg-mem.sh"
chmod +x /root/mrtg-mem.sh
service snmpd restart
chkconfig snmpd on
snmpwalk -v 1 -c public localhost | tail
mkdir -p /home/vps/public_html/mrtg
cfgmaker --zero-speed 100000000 --global 'WorkDir: /home/vps/public_html/mrtg' --output /etc/mrtg/mrtg.cfg public@localhost
curl "http://script.hostingtermurah.net/repo/mrtg.conf" >> /etc/mrtg.cfg
sed -i 's/WorkDir: \/var\/www\/mrtg/# WorkDir: \/var\/www\/mrtg/g' /etc/mrtg/mrtg.cfg
sed -i 's/# Options\[_\]: growright, bits/Options\[_\]: growright/g' /etc/mrtg/mrtg.cfg
indexmaker --output=/home/vps/public_html/mrtg/index.html /etc/mrtg/mrtg.cfg
echo "0-59/5 * * * * root env LANG=C /usr/bin/mrtg /etc/mrtg/mrtg.cfg" > /etc/cron.d/mrtg
LANG=C /usr/bin/mrtg /etc/mrtg/mrtg.cfg
LANG=C /usr/bin/mrtg /etc/mrtg/mrtg.cfg
LANG=C /usr/bin/mrtg /etc/mrtg/mrtg.cfg
cd

# setting port ssh
sed -i '/Port 22/a Port 143' /etc/ssh/sshd_config
sed -i '/Port 22/a Port  90' /etc/ssh/sshd_config
sed -i 's/#Port 22/Port  22/g' /etc/ssh/sshd_config
service sshd restart
chkconfig sshd on

# install dropbear
yum -y install dropbear
echo "OPTIONS=\"-p 109 -p 110 -p 443\"" > /etc/sysconfig/dropbear
echo "/bin/false" >> /etc/shells
service dropbear restart
chkconfig dropbear on

# install vnstat gui
cd /home/vps/public_html/
wget http://script.hostingtermurah.net/repo/vnstat_php_frontend-1.5.1.tar.gz
tar xf vnstat_php_frontend-1.5.1.tar.gz
rm vnstat_php_frontend-1.5.1.tar.gz
mv vnstat_php_frontend-1.5.1 vnstat
cd vnstat
sed -i 's/eth0/venet0/g' config.php
sed -i "s/\$iface_list = array('venet0', 'sixxs');/\$iface_list = array('venet0');/g" config.php
sed -i "s/\$language = 'nl';/\$language = 'en';/g" config.php
sed -i 's/Internal/Internet/g' config.php
sed -i '/SixXS IPv6/d' config.php
cd

# install fail2ban
yum -y install fail2ban
service fail2ban restart
chkconfig fail2ban on

# install squid
yum -y install squid
cat > /etc/squid/squid.conf <<-END
acl manager proto cache_object
acl localhost src 127.0.0.1/32 ::1
acl to_localhost dst 127.0.0.0/8 0.0.0.0/32 ::1
acl localnet src 10.0.0.0/8
acl localnet src 172.16.0.0/12
acl localnet src 192.168.0.0/16
acl localnet src fc00::/7
acl localnet src fe80::/10
acl SSL_ports port 443
acl Safe_ports port 80
acl Safe_ports port 21
acl Safe_ports port 443
acl Safe_ports port 70
acl Safe_ports port 210
acl Safe_ports port 1025-65535
acl Safe_ports port 280
acl Safe_ports port 488
acl Safe_ports port 591
acl Safe_ports port 777
acl CONNECT method CONNECT
acl SSH dst xxxxxxxxx-xxxxxxxxx/32
http_access allow SSH
http_access allow manager localhost
http_access deny manager
http_access allow localnet
http_access allow localhost
http_access deny all
http_port 8080
http_port 8000
http_port 80
http_port 3128
hierarchy_stoplist cgi-bin ?
coredump_dir /var/spool/squid
refresh_pattern ^ftp: 1440 20% 10080
refresh_pattern ^gopher: 1440 0% 1440
refresh_pattern -i (/cgi-bin/|\?) 0 0% 0
refresh_pattern . 0 20% 4320
visible_hostname Proxy.HostingTermurah.net
END
sed -i $MYIP2 /etc/squid/squid.conf;
service squid restart
chkconfig squid on

# install webmin
cd
wget "http://script.hostingtermurah.net/repo/webmin-1.801-1.noarch.rpm"
yum -y install perl perl-Net-SSLeay openssl perl-IO-Tty
rpm -i webmin-1.801-1.noarch.rpm;
rm webmin-1.801-1.noarch.rpm
sed -i 's/ssl=1/ssl=0/g' /etc/webmin/miniserv.conf
service webmin restart
chkconfig webmin on

# pasang bmon
yum -y install bmon

# Install Menu
cd
wget https://github.com/mastavps/menuu/raw/master/menu.sh
mv ./menu /usr/local/bin/menu
chmod +x /usr/local/bin/menu

# cron
service crond start
chkconfig crond on

# set time GMT +7
ln -fs /usr/share/zoneinfo/Asia/Kuala_Lumpur /etc/localtime

# finalisasi
chown -R nginx:nginx /home/vps/public_html
service nginx start
service php-fpm start
service vnstat restart
service openvpn restart
service snmpd restart
service sshd restart
service dropbear restart
service fail2ban restart
service squid restart
service webmin restart
service pptpd restart
service crond start
chkconfig crond on

# info
clear
echo " "
echo "Instaslasi telah selesai! Mohon baca dan simpan penjelasan setup server!"
echo " "
echo "--------------------------- Penjelasan Setup Server ----------------------------"
echo "                         Copyright HostingTermurah.net                          "
echo "                        https://www.hostingtermurah.net                         "
echo "               Created By Steven Indarto(fb.com/stevenindarto2)                 "
echo "--------------------------------------------------------------------------------"
echo ""  | tee -a log-install.txt
echo "Informasi Server"  | tee -a log-install.txt
echo "   - Timezone    : Asia/Jakarta (GMT +7)"  | tee -a log-install.txt
echo "   - Fail2Ban    : [on]"  | tee -a log-install.txt
echo "   - IPtables    : [on]"  | tee -a log-install.txt
echo "   - Auto-Reboot : [off]"  | tee -a log-install.txt
echo "   - IPv6        : [off]"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "Informasi Aplikasi & Port"  | tee -a log-install.txt
echo "   - OpenVPN     : TCP 1194 "  | tee -a log-install.txt
echo "   - OpenSSH     : 22, 143"  | tee -a log-install.txt
echo "   - Dropbear    : 109, 110, 443"  | tee -a log-install.txt
echo "   - Squid Proxy : 80, 3128, 8000, 8080 (limit to IP Server)"  | tee -a log-install.txt
echo "   - Badvpn      : 7300"  | tee -a log-install.txt
echo "   - Nginx       : 85"  | tee -a log-install.txt
echo "   - PPTP VPN    : 1732"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "Informasi Tools Dalam Server"  | tee -a log-install.txt
echo "   - htop"  | tee -a log-install.txt
echo "   - iftop"  | tee -a log-install.txt
echo "   - mtr"  | tee -a log-install.txt
echo "   - nethogs"  | tee -a log-install.txt
echo "   - screenfetch"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "Informasi Premium Script"  | tee -a log-install.txt
echo "   Perintah untuk menampilkan daftar perintah: menu"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "   Penjelasan script dan setup VPS"| tee -a log-install.txt
echo "   dapat dilihat di: http://bit.ly/penjelasansetup"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "Informasi Penting"  | tee -a log-install.txt
echo "   - Download Config OpenVPN : http://$MYIP:85/client.ovpn"  | tee -a log-install.txt
echo "     Mirror (*.tar.gz)       : http://$MYIP:85/openvpn.tar.gz"  | tee -a log-install.txt
echo "   - Webmin                  : http://$MYIP:10000/"  | tee -a log-install.txt
echo "   - Vnstat                  : http://$MYIP:85/vnstat/"  | tee -a log-install.txt
echo "   - MRTG                    : http://$MYIP:85/mrtg/"  | tee -a log-install.txt
echo "   - Log Instalasi           : cat /root/log-install.txt"  | tee -a log-install.txt
echo "     NB: User & Password Webmin adalah sama dengan user & password root"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "----------- Script Created By Steven Indarto(fb.com/stevenindarto2) ------------"
