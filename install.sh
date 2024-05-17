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
mysql_user="${domain%%.*}"
mysql_pass=`openssl rand -base64 8`
mysql_pass_root=`openssl rand -base64 16`
mysql_database="${domain%%.*}"
api_storage="https://storage.job3s.vn"
#access_key="2jic3LO7nv1D8ijaOZWQ"
#secrect_key="ubuHqhZkTwLvux8Tqp2qffT6WOQxLUONIcGTOEdK"
read -p "Nhap Access Key duoc cung cap: " access_key
read -p "Nhap Secrect Key duoc cung cap: " secrect_key
echo -e "\033[1;33mDang kiem tra Key...\033[0m"
#access_key="2jic3LO7nv1D8ijaOZWQ"
#secrect_key="ubuHqhZkTwLvux8Tqp2qffT6WOQxLUONIcGTOEdK"
wget -q https://dl.min.io/client/mc/release/linux-amd64/mc -O /usr/local/bin/mc -o /dev/null
chmod +x /usr/local/bin/mc
mc alias set minio $api_storage $access_key $secrect_key >> /dev/null
if mc ls minio/source &> /dev/null; then
    echo -e "\033[0;32mAccess Key va Secret Key hop le.\033[0m"
    echo "Bat dau qua trinh cai dat........................"
else
    echo -e "\033[0;31mAccess Key va Secret Key khong dung. Vui long nhap lai\033[0m"
    exit 1
fi
#2.setting enviroment
timedatectl set-timezone Asia/Ho_Chi_Minh
apt-get install zip unzip vim net-tools git expect curl -y >> /dev/null
curl -Lso- https://raw.githubusercontent.com/nhanhoadocs/ghichep-cmdlog/master/cmdlog.sh | bash
ufw allow 80 >> /dev/null
ufw allow 443 >> /dev/null
ufw allow 22 >> /dev/null
expect -c 'set timeout 2; spawn ufw enable; expect "Command may disrupt existing ssh connections. Proceed with operation (y|n)?"; send "y\n"; interact' >> /dev/null
systemctl restart ufw
#2.1.install redis
apt-get install redis-server -y >> /dev/null
systemctl enable redis-server
systemctl restart redis-server
pid_redis=`systemctl status redis-server | grep "Main PID" | awk '{print $3}'`
echo -e "\033[0;32m(1/5) Cai dat thanh cong Redis. PID running: $pid_redis\033[0m"
#2.1.install php
apt-get install software-properties-common -y >> /dev/null
expect -c 'set timeout 2; spawn add-apt-repository ppa:ondrej/php; expect "Press \[ENTER\] to continue or Ctrl-c to cancel adding it."; send "\r"; interact' >> /dev/null
apt-get install php$version_php-cli php$version_php-fpm php$version_php-mbstring php$version_php-zip php$version_php-xml php$version_php-curl php$version_php-gd php$version_php-mysql php$version_php-redis -y >> /dev/null
systemctl enable php$version_php-fpm
systemctl restart php$version_php-fpm
pid_php_fpm=`systemctl status php$version_php-fpm | grep "Main PID" | awk '{print $3}'`
echo -e "\033[0;32m(2/5) Cai dat thanh cong php$version_php-fpm. PID running: $pid_php_fpm\033[0m"
#2.2.install mysql
apt-get install mysql-server -y >> /dev/null
expect -c  'set timeout 2;
            spawn mysql_secure_installation;
            expect "Press y|Y for Yes, any other key for No:";
            send "n\n";
            expect "Remove anonymous users? (Press y|Y for Yes, any other key for No) :";
            send "y\n";
            expect "Disallow root login remotely? (Press y|Y for Yes, any other key for No) :";
            send "n\n";
            expect "Remove test database and accescs to it? (Press y|Y for Yes, any other key for No) :";
            send "y\n";
            expect "Reload privilege tables now? (Press y|Y for Yes, any other key for No) :";
            send "y\n";
            interact' >> /dev/null
mv /etc/mysql/mysql.conf.d/mysqld.cnf /etc/mysql/mysql.conf.d/mysqld.cnf.ori
mc cp minio/config/mysqld.cnf /etc/mysql/mysql.conf.d/
mysql -u root --password="" -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$mysql_pass_root'"
mysql -u root --password="$mysql_pass_root" -e "CREATE USER 'root'@'%' IDENTIFIED WITH mysql_native_password BY '$mysql_pass_root'"
mysql -u root --password="$mysql_pass_root" -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost'"
mysql -u root --password="$mysql_pass_root" -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%'"
mysql -u root --password="$mysql_pass_root" -e "create database `$mysql_database`"
mysql -u root -e "CREATE USER `$mysql_user`@'%' IDENTIFIED WITH mysql_native_password BY '$mysql_pass'"
mysql -u root -e "GRANT SELECT, INSERT, UPDATE, DELETE ON $mysql_database.* TO '$mysql_user'@'%'"
mysql -u root -e "FLUSH PRIVILEGES"
systemctl enable mysql
systemctl restart mysql
pid_mysql_server=`systemctl status mysql | grep "Main PID" | awk '{print $3}'`
echo -e "\033[0;32m(3/5) Cai dat thanh cong mysql-8. PID running: $pid_mysql_server\033[0m"
#2.3.install nginx
apt-get update >> /dev/null
apt-get upgrade -y  >> /dev/null
apt-get install nginx -y
systemctl enable nginx
mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.ori
mc cp minio/config/nginx.conf /etc/nginx/nginx.conf
mkdir -p /etc/nginx/ssl_cert/$domain/
mc cp minio/config/domain.conf /etc/nginx/conf.d/domain.conf
sed -i "s/domain/$domain/g" /etc/nginx/conf.d/domain.conf
sed -i "s/version_php/$version_php/g" domain.conf
mv /root/domain.conf /etc/nginx/conf.d/$domain.conf
#cp /root/$domain.* /etc/nginx/ssl_cert/$domain/
systemctl restart nginx
pid_nginx=`systemctl status nginx | grep "Main PID" | awk '{print $3}'`
echo -e "\033[0;32m(4/5) Cai dat thanh cong nginx. PID running: $pid_nginx\033[0m"
#3.1.restore database
mc cp minio/source/sql.zip /tmp/
cd /tmp/ && unzip sql.zip >> /dev/null
mysql -u "$mysql_user" --password="$mysql_pass" "$mysql_database" < /tmp/*.sql
#3.2.unzip source code
echo -e "\033[0;32m(5/5) Dang cap nhat du lieu...............\033[0m"
mkdir -p /var/www/html/
mc cp minio/source/source.zip /var/www/html/
cd /var/www/html && unzip source.zip >> /dev/null
cd /var/www/html && rm -rf source.zip
cd /var/www/html && mv source $domain
rm -rf /var/www/html/$domain/.env
mc cp minio/config/.env /var/www/html/$domain/
cd /var/www/html/$doamin && sed -i "s/domain/$domain/g" /var/www/html/$domain/.env
cd /var/www/html/$doamin && sed -i "s/mysql_user/$mysql_user/g" /var/www/html/$domain/.env
cd /var/www/html/$doamin && sed -i "s/mysql_pass/$mysql_pass/g" /var/www/html/$domain/.env
cd /var/www/html/$doamin && sed -i "s/mysql_database/$mysql_database/g" /var/www/html/$domain/.env
cd /var/www/html/$domain/ && rm -rf bootstrap/cache
cd /var/www/html/$domain/ && mkdir -p bootstrap/cache
cd /var/www/html/$domain/ && chmod -R 777 bootstrap/cache
cd /var/www/html/$domain/ && chmod -R 777 strorage
cd /var/www/html/$domain/ && php artisan cache:clear
cd /var/www/html/$domain/ && php artisan optimize
cd /var/www/html/$domain/ && php artisan route:clear
echo -e "\033[0;32m(4/4) Cap nhat du lieu thanh cong\033[0m"
systemctl restart nginx
pid_nginx=`systemctl status nginx | grep "Main PID" | awk '{print $3}'`
ip_public=`curl -s ifconfig.me`
date1=$(date '+%Y%m%d_%H%M')
touch /tmp/$domain_$date1.log
echo "Thong tin cai dat domain $domain" >> /tmp/$ip_public_$date1.log
echo "IP Public = $ip_public" >> /tmp/$ip_public_$date1.log
echo "Database Name = $mysql_database" >> /tmp/$ip_public_$date1.log
echo "Database User = $mysql_user" >> /tmp/$ip_public_$date1.log
echo "Database Pass = $mysql_pass" >> /tmp/$ip_public_$date1.log
mc cp /tmp/$ip_public_$date1.log minio/logs/
#web_status=`curl -o /dev/null -s -w '%{http_code}' https://$domain`
