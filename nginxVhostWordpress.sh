#!/bin/bash

if [ "$(whoami)" != 'root' ]; then
	echo "You have no permission to run $0 as non-root user. Use sudo"
	exit 1;
fi

domain=$1
rootPath=$2
sitesEnable='/etc/nginx/sites-enabled/'
sitesAvailable='/etc/nginx/sites-available/'
# Example: /var/www/hmtl/domain/public_html
serverRoot='/var/www/html/'
publicHtml='/public_html'
user='userName'
webUser='www-data'

while [ "$domain" = "" ]
do
	echo "Please provide domain:"
	read domain
done

if [ -e $sitesAvailable$domain ]; then
	echo "This domain already exists.\nPlease Try Another one"
	exit;
fi

if [ "$rootPath" = "" ]; then
	rootPath=$serverRoot$domain$publicHtml
fi

if ! [ -d $rootPath ]; then
	mkdir -p $rootPath
	# chmod 777 $rootPath
	if ! echo "Hello, world!" > $rootPath/index.php
	then
		echo "ERROR: Not able to write in file $rootPath/index.php. Please check permissions."
		exit;
	else
		echo "Added content to $rootPath/index.php"
	fi
fi

chown -R $user:$webUser $serverRoot$domain

if ! [ -d $sitesEnable ]; then
	mkdir $sitesEnable
	# chmod 777 $sitesEnable
fi

if ! [ -d $sitesAvailable ]; then
	mkdir $sitesAvailable
	# chmod 777 $sitesAvailable
fi

configName=$domain

if ! echo "
server {
    listen 80;
    server_name $domain www.$domain;
    access_log /var/www/log/nginx/$domain-access.log;
    error_log /var/www/log/nginx/$domain-error.log;
    root $serverRoot$domain$publicHtml;
    index index.php;
    error_page 404 /404.html;
    error_page 500 502 503 504 /50x.html;
    location / { 
        try_files \$uri \$uri/ /index.php?\$args; 
    }
    location = /favicon.ico {
       log_not_found off;
       access_log off;
    }
    location = /robots.txt {
       allow all;
       log_not_found off;
       access_log off;
    }
    location ~ \.php$ {
       try_files \$uri =404;
       fastcgi_pass unix:/var/run/php/php7.3-fpm.sock;
       fastcgi_index index.php;
       fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
       include fastcgi_params;
    }
    location ~* ^.+\.(jpg|jpeg|gif|png|ico|css|zip|tgz|gz|js)$ {
       root $serverRoot$domain$publicHtml/;
    }
    location ~ /\.ht {
        deny all;
    }
    client_max_body_size 0;
}
" > $sitesAvailable$configName
then
    echo "There is an ERROR create $configName file."
    exit;
else
    echo "New Virtual Host Created"
fi

ln -s $sitesAvailable$configName $sitesEnable$configName

service nginx restart

echo "Complete! \nYou now have a new Virtual Host \nYour new host is: http://$domain \nAnd its located at $rootPath"
exit;
