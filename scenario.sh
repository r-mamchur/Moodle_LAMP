#!/bin/bash

#  Apache
yum install -y httpd
systemctl start  httpd
systemctl enable httpd

# MySql
rpm -Uvh  https://repo.mysql.com/yum/mysql-5.7-community/el/7/x86_64/mysql-community-release-el7-7.noarch.rpm
yum-config-manager -q -y --enable mysql57-community
yum-config-manager -q -y --disable mysql56-community
yum install -y mysql-community-server
systemctl start mysqld.service
systemctl enable mysqld.service

# PHP
yum install -y http://rpms.remirepo.net/enterprise/remi-release-7.rpm
yum-config-manager --enable remi-php73
yum install -y epel-release
yum install -y php php-zip php-gd php-intl php-mbstring php-soap php-xmlrpc php-pgsql \
   php-opcache libsemanage-python libselinux-python php-pecl-redis 
# it's need for moodle
yum install -y php-mysqli
# "Nothing to do" but ....
yum install -y  php-iconv php-curl php-ctype php-simplexml php-spl                


# conf connect to MySql
# password - Passw0rd!  
MYSQL_TEMP_PWD=`sudo cat /var/log/mysqld.log | grep 'A temporary password is generated' | awk -F'root@localhost: ' '{print $2}'`
mysqladmin -u root -p`echo $MYSQL_TEMP_PWD` password 'Passw0rd!'

# mysql --defaults-file=~/.my.cnf     use for connect to mysql
cat << EOF > ~/.my.cnf
 [client]
user=root
password=Passw0rd!
EOF
chmod 600 ~/.my.cnf

yum install -y wget
yum install -y unzip
yum install -y mc

# moodle
mysql --defaults-file=~/.my.cnf </vagrant/moodle.sql
wget https://download.moodle.org/download.php/direct/stable36/moodle-latest-36.tgz
tar -xz -f moodle-latest-36.tgz -C /var/www
wget https://download.moodle.org/langpack/3.6/uk.zip
unzip uk.zip -d /var/www/moodle/lang
rm moodle-latest-36.tgz -f
rm uk.zip -f
mkdir /var/moodledata
chmod 0744 /var/moodledata
/usr/bin/php /var/www/moodle/admin/cli/install.php --wwwroot=http://moodle.test --dataroot=/var/moodledata --dbtype=mysqli --dbhost=localhost --dbname=moodle --dbuser=moodleuser --dbpass=Passw0rd! --fullname="Moodle forever" --adminpass=Passw0rd!  --shortname="Moodle site" --non-interactive --agree-license --lang=ua

#  SELinux
chcon -t httpd_sys_rw_content_t /var/moodledata -R
setsebool -P httpd_can_network_connect on
setsebool -P httpd_can_network_memcache on
setsebool -P httpd_can_network_connect_db     # if DB in other host

#VirtualHost
cp /vagrant/moodle.conf /etc/httpd/conf.d
chown apache:apache /var/moodledata -R
chown apache:apache /var/www/moodle  -R
systemctl restart httpd.service

# cron every 5 minutes
echo "*/5 * * * * root /usr/bin/wget -O /dev/null http://localhost/moodle/admin/cron.php" >> /etc/crontab
systemctl restart crond.service

