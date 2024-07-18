#!/bin/bash

# Configuration
php_version="8.2"  # Example: latest or 8.2
mysql_root_password="root"  # Not less than 4 symbols
mysql_user_username="user"  # Not less than 3 symbols
mysql_user_password="user"  # Not less than 4 symbols
install_snap_certbot=false
set_as_default_php_version=true  # Works only if php_version above is not latest

# Configuration validation
if [ -z "$php_version" ]; then
    echo "PHP Version is not specified. Please configure it by editing this file"
    exit 1
fi
if [[ "$php_version" == "latest" ]]; then
    php_version=""
elif ! [[ "$php_version" =~ ^([0-9]+\.)?([0-9]+\.)?([0-9]+)$ ]]; then
    echo "Invalid php version specified"
    exit 1
fi
if [[ ${#mysql_root_password} -lt 4 ]]; then
    echo "MySQL root password should not be less than 4 symbols"
    exit 1
fi
if [[ ${#mysql_user_username} -lt 3 ]]; then
    echo "MySQL user username should not be less than 3 symbols"
    exit 1
fi
if [[ ${#mysql_user_password} -lt 4 ]]; then
    echo "MySQL user password should not be less than 4 symbols"
    exit 1
fi

# Installation
sudo apt update
sudo apt install -y software-properties-common
sudo apt install -y nginx
sudo systemctl enable nginx
sudo apt install -y openssl wget imagemagick
sudo add-apt-repository ppa:ondrej/php
sudo apt update
php_pref="php$php_version"
sudo apt install -y $php_pref php-json $php_pref-dev $php_pref-mysql $php_pref-common $php_pref-cli $php_pref-fpm $php_pref-bz2 $php_pref-curl $php_pref-gd $php_pref-dom $php_pref-intl $php_pref-mbstring $php_pref-zip $php_pref-pgsql $php_pref-sqlite3 $php_pref-memcache $php_pref-apcu $php_pref-imagick
sudo systemctl enable $php_pref-fpm
if [[ "$php_version" && "$set_as_default_php_version" == "true" ]]; then
    sudo update-alternatives --set php /usr/bin/$php_pref
fi
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php composer-setup.php
sudo mv composer.phar /usr/bin/composer
sudo rm composer-setup.php
exit 1
sudo apt install -y mysql-server
sudo mysql -e "INSTALL PLUGIN validate_password SONAME 'validate_password.so';"
sudo mysql -e "SET GLOBAL validate_password_policy=LOW;"
sudo mysql -e "SET GLOBAL validate_password_length=4;"
sudo mysql -e "SET GLOBAL validate_password_mixed_case_count=0;"
sudo mysql -e "SET GLOBAL validate_password_number_count=0;"
sudo mysql -e "SET GLOBAL validate_password_special_char_count=0;"
sudo mysql -e "SET GLOBAL validate_password_check_user_name=FALSE;"
sudo mysql -e "CREATE USER '$mysql_user_username'@'localhost' IDENTIFIED WITH mysql_native_password BY '$mysql_user_password'";
sudo mysql -e "GRANT ALL PRIVILEGES ON * . * TO '$mysql_user_username'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$mysql_root_password';"
sudo mysql_secure_installation
sudo systemctl restart mysql.service
wget https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.gz
tar -xzf phpMyAdmin-*.gz
rm ./phpMyAdmin-*.gz
sudo mv ./phpMyAdmin-* /usr/share/phpmyadmin
randomBlowfishSecret=$(openssl rand -base64 24) # Generate random string of 32 Bytes
sudo sed -e "s|cfg\['blowfish_secret'\] = ''|cfg['blowfish_secret'] = '$randomBlowfishSecret'|" /usr/share/phpmyadmin/config.sample.inc.php > /usr/share/phpmyadmin/config.inc.php
sudo mkdir -m 777 /usr/share/phpmyadmin/tmp
if [ "$install_snap_certbot" == "true" ]; then
    sudo snap install --classic certbot
fi
