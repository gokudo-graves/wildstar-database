#!/usr/bin/env bash

################
# Base install #
################

# MS .net core
wget -q https://packages.microsoft.com/config/ubuntu/16.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo add-apt-repository universe

echo "Update Package List"
sudo apt-get update

echo "Update System Packages"
sudo apt-get upgrade -y

echo "Install Some Basic Packages"
sudo apt-get install -y curl dos2unix gcc git libmcrypt4 libpcre3-dev ntp unzip make \
python3.7-dev python-pip re2c supervisor unattended-upgrades whois libnotify-bin pv \
cifs-utils vim gnupg ca-certificates util-linux libc-dev g++ autoconf sqlite3 libsqlite3-dev \
dotnet-sdk-3.1

# Set Locale
#sudo update-locale "de_DE.UTF-8"
#sudo locale-gen "de_DE.UTF-8"
#sudo loadkeys de
# for permanet layout change use:
# sudo dpkg-reconfigure keyboard-configuration

# Set Timezone
sudo ln -sf /usr/share/zoneinfo/UTC /etc/localtime


################
# PHP & APACHE #
################

echo "Installing PHP & Apache..."

sudo apt-add-repository -y ppa:ondrej/apache2
sudo apt-add-repository -y ppa:ondrej/php
sudo apt-add-repository -y ppa:chris-lea/redis-server

#sudo apt install gnupg ca-certificates
#sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
#echo "deb https://download.mono-project.com/repo/ubuntu stable-bionic main" | sudo tee /etc/apt/sources.list.d/mono-official-stable.list

sudo apt-get update

# Apache & PHP
# --allow-downgrades --allow-remove-essential --allow-change-held-packages
sudo apt-get install -y -qq \
apache2 libapache2-mod-php7.4 php7.4-common \
php7.4-cli php7.4-bcmath php7.4-bz2 php7.4-curl php7.4-dev php7.4-enchant \
php7.4-gd php7.4-gmp php7.4-imap php7.4-intl php7.4-json php7.4-mbstring \
php7.4-opcache php7.4-phpdbg php7.4-pspell php7.4-readline \
php7.4-soap php7.4-xml php7.4-zip php7.4-memcached \
php7.4-mysql php7.4-sqlite3 php7.4-imagick \
php-xdebug php-pear redis-server memcached imagemagick liblzma-dev
#mono-complete libapache2-mod-mono mod-mono-server mono-xsp4 referenceassemblies-pcl

sudo systemctl stop apache2
sudo pecl channel-update pecl.php.net

# PHP-Apache2/FPM Options
sudo sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.4/apache2/php.ini
sudo sed -i "s/display_errors = .*/display_errors = On/" /etc/php/7.4/apache2/php.ini
sudo sed -i "s/memory_limit = .*/memory_limit = 2G/" /etc/php/7.4/apache2/php.ini
sudo sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php/7.4/apache2/php.ini
sudo sed -i "s/upload_max_filesize = .*/upload_max_filesize = 128M/" /etc/php/7.4/apache2/php.ini
sudo sed -i "s/post_max_size = .*/post_max_size = 128M/" /etc/php/7.4/apache2/php.ini

# PHP CLI Settings
sudo sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.4/cli/php.ini
sudo sed -i "s/display_errors = .*/display_errors = On/" /etc/php/7.4/cli/php.ini
sudo sed -i "s/memory_limit = .*/memory_limit = 8G/" /etc/php/7.4/cli/php.ini
sudo sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php/7.4/cli/php.ini

sudo echo "xdebug.remote_enable = 1" >> /etc/php/7.4/mods-available/xdebug.ini
sudo echo "xdebug.remote_connect_back = 1" >> /etc/php/7.4/mods-available/xdebug.ini
sudo echo "xdebug.remote_port = 9000" >> /etc/php/7.4/mods-available/xdebug.ini
sudo echo "xdebug.max_nesting_level = 512" >> /etc/php/7.4/mods-available/xdebug.ini
sudo echo "opcache.revalidate_freq = 0" >> /etc/php/7.4/mods-available/opcache.ini

# PHPRedis
sudo pecl install redis
sudo echo "extension=redis" > /etc/php/7.4/mods-available/redis.ini

# APCU
#sudo pecl install apcu
#sudo printf "extension=apcu\napc.enable=1\napc.enable_cli=1" > /etc/php/7.4/mods-available/apcu.ini

# xz (LZMA2)
mkdir /usr/share/xz
git clone https://github.com/codemasher/php-xz.git /usr/share/xz
cd /usr/share/xz/ && phpize && ./configure && make && make install
sudo echo "extension=xz" > /etc/php/7.4/mods-available/xz.ini

# install global composer
curl -sS https://getcomposer.org/installer | php
chmod +x composer.phar
mv composer.phar /usr/local/bin/composer
printf "\nPATH=\"$(sudo su - vagrant -c 'composer config -g home 2>/dev/null')/vendor/bin:\$PATH\"\n" | tee -a /home/vagrant/.profile
composer about

# Install global PHPUnit
#wget -q https://phar.phpunit.de/phpunit.phar
#chmod +x phpunit.phar
#mv phpunit.phar /usr/local/bin/phpunit
#phpunit --version

# Apache config
sudo cp /vagrant/config/defaultsite.conf /etc/apache2/sites-available/vagrant.conf
sudo a2enmod setenvif rewrite actions alias headers deflate # mod_mono
sudo phpenmod xdebug opcache redis apcu xz
sudo a2dissite 000-default
sudo a2ensite vagrant

sudo systemctl reload-or-restart apache2
sudo systemctl enable apache2


######################
# MySQL & PHPMyAdmin #
######################

echo "Installing MYSQL... (user: $BOX_DBUSER, pass:$BOX_DBPASS)"

sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $BOX_DBPASS"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $BOX_DBPASS"
sudo apt-get install -y mysql-server

sudo cp /vagrant/config/mysqld.cnf /etc/mysql/mysql.conf.d/mysqld.cnf

# Configure MySQL Remote Access
sudo mysql --user="root" --password="$BOX_DBPASS" -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$BOX_DBPASS' WITH GRANT OPTION;"
sudo mysql --user="root" --password="$BOX_DBPASS" -e "CREATE USER '$BOX_DBUSER'@'localhost' IDENTIFIED BY '$BOX_DBPASS';"
sudo mysql --user="root" --password="$BOX_DBPASS" -e "GRANT ALL PRIVILEGES ON *.* TO '$BOX_DBUSER'@'localhost' IDENTIFIED BY '$BOX_DBPASS' WITH GRANT OPTION;"
sudo mysql --user="root" --password="$BOX_DBPASS" -e "GRANT ALL PRIVILEGES ON *.* TO '$BOX_DBUSER'@'%' IDENTIFIED BY '$BOX_DBPASS' WITH GRANT OPTION;"
sudo mysql --user="root" --password="$BOX_DBPASS" -e "FLUSH PRIVILEGES;"
sudo mysql --user="root" --password="$BOX_DBPASS" -e "CREATE DATABASE $BOX_DBUSER character set UTF8mb4 collate utf8mb4_bin;"
sudo service mysql restart

ln -s /var/lib/mysql/mysql.sock /tmp/mysql.sock

# PHPMyAdmin
cd /home/vagrant
wget -q https://files.phpmyadmin.net/phpMyAdmin/5.0.2/phpMyAdmin-5.0.2-all-languages.tar.gz
tar -xzf phpMyAdmin-5.0.2-all-languages.tar.gz -C /usr/share
mv /usr/share/phpMyAdmin-5.0.2-all-languages /usr/share/phpmyadmin
cd /usr/share/phpmyadmin
composer install --no-dev --no-interaction --prefer-dist
cd /home/vagrant
rm phpMyAdmin-5.0.2-all-languages.tar.gz

cp /vagrant/config/phpmyadmin.config.php /usr/share/phpmyadmin/config.inc.php

sudo systemctl reload apache2


########
# Misc #
########

# Configure Supervisor
systemctl enable supervisor.service
service supervisor start

# Clean Up
apt-get -y autoremove
apt-get -y clean

# Enable Swap Memory
/bin/dd if=/dev/zero of=/var/swap.1 bs=1M count=1024
/sbin/mkswap /var/swap.1
/sbin/swapon /var/swap.1

# Minimize The Disk Image
#echo "Minimizing disk image..."
#dd if=/dev/zero of=/EMPTY bs=1M
#rm -f /EMPTY
#sync
echo "done."
