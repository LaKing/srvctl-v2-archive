#!/bin/bash

if $onVE  && $isROOT
then ## no identation.

        hint "add-wordpress [path]" "Install Wordpress. Optionally to a folder (URI)."
        if [ "$CMD" == "add-wordpress" ]
        then
                yum -y install wordpress

                setup_mariadb

                URI=$2



                if [ -z $URI ]
                then
                        dir=/var/www/html
                        dbd=$(cat /etc/hostname | cut -f1 -d"." )'_wp'
                        bak /var/www/html/index.html
                        rm -rf /var/www/html/index.html
                else        
                        if [ -d /var/www/html/$URI ]
                        then
                                err "$URI already exists."
                                exit
                        fi
                
                        mkdir /var/www/html/$URI
                        dir=/var/www/html/$URI
                        dbd=$(cat /etc/hostname | cut -f1 -d"." )'_wp_'$URI                
                fi

                ## for dependencies.
                yum -y install unzip
                yum -y install wordpress

                ## set params in php.ini, ...          
                sed_file /etc/php.ini ";date.timezone =" "date.timezone = $php_timezone"
                sed_file /etc/php.ini  "upload_max_filesize = 2M" "upload_max_filesize = 25M"
                sed_file /etc/php.ini  "post_max_size = 8M" "post_max_size = 25M"

                wd=/root
                curl https://wordpress.org/latest.zip > $wd/latest.zip
        
                unzip $wd/latest.zip -d $wd >> $wd/unzip.log
                cp -u -f -r $wd/wordpress/* $dir
                rm -rf $wd/latest.zip
                rm -rf $wd/wordpress
                rm -rf $wd/unzip.log
                chown -R apache:apache $dir
        
                cf=$dir/wp-config.php

                add_mariadb_db        

                ## save these params to the wp folder
                f=$dir/wp-config.php
                
                if [ -f "$f" ]
                then
                    msg "There is already a config file. Creating a backup."
                    bak $f
                fi

                
                echo "<?php" > $f
                echo "// srvctl wordpress wp-config" >> $f
                echo "define('DB_NAME', '$db_name');" >> $f
                echo "define('DB_USER', '$db_usr');" >> $f
                echo "define('DB_PASSWORD', '$db_pwd');" >> $f        
                echo "define('DB_HOST', 'localhost');" >> $f
                echo "define('DB_CHARSET', 'utf8');" >> $f
                echo "define('DB_COLLATE', '');" >> $f
                echo "" >> $f        

                ## random key's and salt's
                get_randomstr
                echo "define('AUTH_KEY',         '$randomstr');" >> $f
                get_randomstr
                echo "define('SECURE_AUTH_KEY',  '$randomstr');" >> $f
                get_randomstr
                echo "define('LOGGED_IN_KEY',    '$randomstr');" >> $f
                get_randomstr
                echo "define('NONCE_KEY',        '$randomstr');" >> $f
                get_randomstr
                echo "define('AUTH_SALT',        '$randomstr');" >> $f
                get_randomstr
                echo "define('SECURE_AUTH_SALT', '$randomstr');" >> $f
                get_randomstr
                echo "define('LOGGED_IN_SALT',   '$randomstr');" >> $f
                get_randomstr
                echo "define('NONCE_SALT',       '$randomstr');" >> $f

                echo "" >> $f

                echo '$'"table_prefix  = 'wp_';" >> $f
                echo "" >> $f

                echo "define('WPLANG', '');" >> $f
                echo "define('WP_DEBUG', false);" >> $f
                echo "" >> $f

                echo "define('FORCE_SSL_ADMIN', true);" >> $f
                echo "" >> $f

                echo "if ( !defined('ABSPATH') ) define('ABSPATH', dirname(__FILE__) . '/');" >> $f
                echo "require_once(ABSPATH . 'wp-settings.php');" >> $f
                echo "" >> $f
                

                ## create an installer to install without web dialog
                f=$dir/wp-install.php
                echo "<?php" > $f
                echo "// srvctl wordpress wp-install" >> $f
                echo "define('WP_SITEURL', 'http://"$(hostname)"/"$URI"');" >> $f
                echo "define('WP_INSTALLING',true);" >> $f
                #echo "define('ABSPATH','/var/www/html/"$URI"/');" >> $f
                echo "require_once('$dir/wp-config.php');" >> $f
                echo "require_once('$dir/wp-settings.php');" >> $f
                echo "require_once('$dir/wp-admin/includes/upgrade.php');" >> $f
                echo "require_once('$dir/wp-includes/wp-db.php');" >> $f
                get_password
                echo "wp_install('"$(hostname)"','admin','root@localhost',1,'','"$password"');" >> $f                
                
                php -f $f

                cf=/etc/httpd/conf.d/wp-permalink.conf

                echo '## srvctl generated' >> $cf
                echo '<Directory /var/www/html/'$URI'>' >> $cf
                echo ' <IfModule mod_rewrite.c>' >> $cf
                echo '  RewriteEngine On' >> $cf
                echo '  RewriteBase /'$URI >> $cf
                echo '  RewriteCond %{REQUEST_FILENAME} !-f' >> $cf
                echo '  RewriteCond %{REQUEST_FILENAME} !-d' >> $cf
                echo '  RewriteRule . /index.php [L]' >> $cf
                echo ' </IfModule>' >> $cf
                echo '</Directory>' >> $cf
                echo '' >> $cf

                systemctl restart httpd.service

                echo $password > $dir/.admin
                chmod 000 $dir/.admin

                log "Wordpress instance installed. https://"$(hostname)"/$URI/wp-admin admin:$password"
                
                ## URGENT TODO: fix https for wordpress behind pound
                ## TODO, reset password: UPDATE users SET user_pass = MD5('"(new-password)"') WHERE ID = 1;
        ok
        fi ## install-wordpress

fi

man '
    Install the latest wordpress from wordpress.org, and create configuration files.
    Homepage: https://wordpress.org/
'
