ve anonymous users? (Press y|Y for Yes, any other key for No) :";
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
