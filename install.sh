#!/bin/bash
###created by trando.actvn@gmail.com
if [ `whoami` != "root" ]; then
  echo "Ban phai chay script voi user root!"
  exit 1
fi
#1.setting variable.
check_domain() {
  local domain_regex="^([a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]\.)+[a-zA-Z]{2,}$"
  if [[ $1 =~ $domain_regex ]] || [[ -z "$domain" ]]; then
    echo "Domain hop le."
    return 0
  else
    echo "Domain khong hop le."
    return 1
  fi
}
while true; do
  read -p "Vui long nhap ten domain ban muon cai dat: " domain
  if check_domain "$domain"; then
    #echo -e "\033[1;33mBan da nhap domain: $domain\033[0m"
    break;
  fi
done
while true; do
    echo "Lua chon phien ban PHP su dung:"
    echo "1 - PHP 5.6 "
    echo "2 - PHP 7.4 (recommend)"
    echo "3 - PHP 8.2"
    read -p "Nhap lua chon cua ban (1/2/3): " choice
    case $choice in
        1)
            version_php="5.6"
            break
            ;;
        2)
            version_php="7.4"
            break
            ;;
        3)
            version_php="8.2"
            break
            ;;
        *)
            echo "Lua chon khong hop le. Vui long nhap 1, 2 hoac 3"
        ;;
esac
done
#echo -e "\033[1;33mPhien ban PHP cai dat: $version_php\033[0m"
mysql_user="${domain%%.*}"
mysql_pass=`openssl rand -base64 12`
mysql_database="${domain%%.*}"
#2.setting enviroment
#2.1.general
timedatectl set-timezone Asia/Ho_Chi_Minh
apt install zip unzip vim net-tools git curl -y
curl -Lso- https://raw.githubusercontent.com/nhanhoadocs/ghichep-cmdlog/master/cmdlog.sh | bash
git clone https://github.com/BkavFC/clone-server.git
ufw allow 80
ufw allow 443
ufw allow from $trusted_ip proto tcp to any port 22
ufw allow from $trusted_ip proto tcp to any port 3306
ufw enable -y
systemctl restart ufw
#2.1.install redis
apt install redis-server -y
systemcrl enable redis-server
systemctl restart redis-server
#2.1.install php
apt install software-properties-common
add-apt-repository ppa:ondrej/php
apt install php$version_php-cli php$version_php-fpm php$version_php-mbstring php$version_php-zip php$version_php-xml php$version_php-curl php$version_php-gd php$version_php-mysql php$version_php-redis -y
systemctl enable php$version_php-fpm
systemctl restart php$version_php-fpm
#2.2.install mysql
apt install mysql-server -y
mysql_secure_installation
###config manual
mv /etc/mysql/mysqld.conf.d/mysqld.conf /etc/mysql/mysqld.conf.d/mysqld.conf.ori
cp /root/mysqld.conf /etc/mysql/mysqld.conf.d/
systemctl enable mysql-server
systemctl restart mysql-server
#2.3.install nginx
apt-get update && apt-get upgrade -y
apt-get install nginx -y
systemctl enable nginx
mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.ori
cp /root/clone-server/nginx.conf /etc/nginx/nginx.conf
cp /root/clone-server/domain.conf /etc/nginx/conf.d/$domain.conf
mkdir -p /etc/nginx/ssl_cert/$domain/
cp /root/$domain.* /etc/nginx/ssl_cert/$domain/
#3.update data
#3.1.restore database
unzip *.zip
mysql -u "$mysql_user" --password="$mysql_pass" -e "create database `$mysql_database`"
mysql -u "$mysql_user" --password="$mysql_pass" "$mysql_database" < /root/*.sql
#3.2.unzip source code
mv domain /var/www/html/
sed -i "s/domain/$domain/g" /root/.env
sed -i "s/mysql_user/$mysql_user/g" /root/.env
sed -i "s/mysql_pass/$mysql_pass/g" /root/.env
sed -i "s/mysql_database/$mysql_database/g" /root/.env
cp /root/.env /var/www/html/$domain/
cd /var/www/html/$domain/ && rm -rf bootstrap/cache
cd /var/www/html/$domain/ && mkdir -p bootstrap/cache
cd /var/www/html/$domain/ && chmod -R 777 bootstrap/cache
cd /var/www/html/$domain/ && php artisan cache:clear
cd /var/www/html/$domain/ && php artisan wn:sitemap:run-all
cd /var/www/html/$domain/ && php artisan optimize
cd /var/www/html/$domain/ && php artisan route:clear
systemctl restart nginx
