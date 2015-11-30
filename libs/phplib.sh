function install_php {
                ## for dependencies.
                pm unzip php php-common php-gd php-mcrypt php-pear php-pecl-memcache php-mhash php-mysql php-xml php-mbstring

                ## set php.ini, ...          
                sed_file /etc/php.ini ";date.timezone =" "date.timezone = $(cat /var/srvctl/timezone | xargs)"
                sed_file /etc/php.ini  "upload_max_filesize = 2M" "upload_max_filesize = 25M"
                sed_file /etc/php.ini  "post_max_size = 8M" "post_max_size = 25M"
}

