#!/usr/bin/env bash
echo "启动php-fpm$4"
sudo service php-fpm$4 start
siteTemplate="server
    {
        listen 80;
        server_name  $1 ;
        index index.html index.htm index.php default.html default.htm default.php;
        root  $2;
        access_log  $3;

        include other.conf;
        #error_page   404   /404.html;

        # Deny access to PHP files in specific directory

        include enable-php$4.conf;

        location ~ .*\.(gif|jpg|jpeg|png|bmp|swf)$
        {
            expires      30d;
        }

        location ~ .*\.(js|css)?$
        {
            expires      12h;
        }

        location ~ /.well-known {
            allow all;
        }

        location ~ /\.
        {
            deny all;
        }
    }
"
echo "创建网站目录"
[ ! -e $2 ] && sudo mkdir $2
echo "创建log日志文件"
[ ! -e $3 ] && sudo touch $3
echo "写入nginx站点配置"
echo "$siteTemplate" > "/usr/local/nginx/conf/vhost/$1.conf"

echo "重启nginx"
sudo service nginx start
sudo service nginx reload
