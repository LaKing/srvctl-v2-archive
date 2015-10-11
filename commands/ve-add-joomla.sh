#!/bin/bash

if $onVE && $isROOT
then ## no identation.

        hint "add-joomla [path]" "Install the latest Joomla! "
        if [ "$CMD" == "add-joomla" ]
        then        

                secure_mariadb

                URI=$2

                if [ -z $URI ]
                then
                        dir=/var/www/html
                        dbd=$(cat /etc/hostname | cut -f1 -d"." )'_ja'
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
                        dbd=$(cat /etc/hostname | cut -f1 -d"." )'_ja_'$URI                
                fi
        
                wd=/root/joomla-cms
                
                #### - download joomla!
                ## from git
                cd /root  
                pm install git
                git clone https://github.com/joomla/joomla-cms.git
                rm -rf $wd/.git
                cp -u -f -r $wd/* $dir
                rm -rf $wd                        

                ## use latest zip release
                
                #mkdir -p $wd 
                #joomla_dl=https://`curl http://www.joomla.org/download.html | grep "Stable-Full_Package.zip" |  grep -Po '^.*?\K(?<=https://).*?(?=.zip)' | grep -m 1 download`.zip
                #curl $joomla_dl > $wd/latest.zip 
                #
                #unzip $wd/latest.zip -d $wd >> $wd/unzip.log
                #rm -rf $wd/latest.zip
                #rm -rf $wd/unzip.log
                #cp -u -f -r $wd/* $dir
                #rm -rf $wd
                

                chown -R apache:apache $dir
        

                ## for dependencies.
                pm install unzip php php-common php-gd php-mcrypt php-pear php-pecl-memcache php-mhash php-mysql php-xml php-mbstring

                ## set php.ini, ...          
                sed_file /etc/php.ini ";date.timezone =" "date.timezone = $php_timezone"
                sed_file /etc/php.ini  "upload_max_filesize = 2M" "upload_max_filesize = 25M"
                sed_file /etc/php.ini  "post_max_size = 8M" "post_max_size = 25M"



                add_mariadb_db

                f=$dir/configuration.php
                echo "<?php" > $f
                echo "class JConfig {" >> $f
                echo "        public \$offline = '0';" >> $f
                echo "        public \$offline_message = 'This site is down for maintenance.<br /> Please check back again soon.';" >> $f
                echo "        public \$display_offline_message = '1';" >> $f
                echo "        public \$offline_image = '';" >> $f
                echo "        public \$sitename = '"$(hostname)"';" >> $f
                echo "        public \$editor = 'tinymce';" >> $f
                echo "        public \$captcha = '0';" >> $f
                echo "        public \$list_limit = '20';" >> $f
                echo "        public \$access = '1';" >> $f
                echo "        public \$debug = '0';" >> $f
                echo "        public \$debug_lang = '0';" >> $f
                echo "        public \$dbtype = 'mysqli';" >> $f
                echo "        public \$host = 'localhost';" >> $f
                echo "        public \$user = '$db_usr';" >> $f
                echo "        public \$password = '$db_pwd';" >> $f
                echo "        public \$db = '$db_name';" >> $f
                echo "        public \$dbprefix = 'jos_';" >> $f
                echo "        public \$live_site = '';" >> $f
                get_randomstr
                echo "        public \$secret = '$randomstr';" >> $f
                echo "        public \$gzip = '0';" >> $f
                echo "        public \$error_reporting = 'default';" >> $f
                echo "        public \$helpurl = 'http://help.joomla.org/proxy/index.php?option=com_help&amp;keyref=Help{major}{minor}:{keyref}';" >> $f
                echo "        public \$ftp_host = '';" >> $f
                echo "        public \$ftp_port = '';" >> $f
                echo "        public \$ftp_user = '';" >> $f
                echo "        public \$ftp_pass = '';" >> $f
                echo "        public \$ftp_root = '';" >> $f
                echo "        public \$ftp_enable = '';" >> $f
                echo "        public \$offset = 'UTC';" >> $f
                echo "        public \$mailonline = '1';" >> $f
                echo "        public \$mailer = 'mail';" >> $f
                echo "        public \$mailfrom = 'joomla@"$(hostname)"';" >> $f
                echo "        public \$fromname = '"$(hostname)"';" >> $f
                echo "        public \$sendmail = '/usr/sbin/sendmail';" >> $f
                echo "        public \$smtpauth = '0';" >> $f
                echo "        public \$smtpuser = '';" >> $f
                echo "        public \$smtppass = '';" >> $f
                echo "        public \$smtphost = 'localhost';" >> $f
                echo "        public \$smtpsecure = 'none';" >> $f
                echo "        public \$smtpport = '25';" >> $f
                echo "        public \$caching = '0';" >> $f
                echo "        public \$cache_handler = 'file';" >> $f
                echo "        public \$cachetime = '15';" >> $f
                echo "        public \$MetaDesc = '';" >> $f
                echo "        public \$MetaKeys = '';" >> $f
                echo "        public \$MetaTitle = '1';" >> $f
                echo "        public \$MetaAuthor = '1';" >> $f
                echo "        public \$MetaVersion = '0';" >> $f
                echo "        public \$robots = '';" >> $f
                echo "        public \$sef = '1';" >> $f
                echo "        public \$sef_rewrite = '0';" >> $f
                echo "        public \$sef_suffix = '0';" >> $f
                echo "        public \$unicodeslugs = '0';" >> $f
                echo "        public \$feed_limit = '10';" >> $f
                echo "        public \$log_path = '"$dir"/logs';" >> $f
                echo "        public \$tmp_path = '"$dir"/tmp';" >> $f
                echo "        public \$lifetime = '15';" >> $f
                echo "        public \$session_handler = 'database';" >> $f
                echo "  public \$force_ssl = '1';" >> $f
                echo "}" >> $f

                dbf=$dir/installation/sql/mysql/joomla.sql

                sed_file $dbf "#__" "jos_"

                mysql $MDA -e "USE $db_name; source $dbf;"
        
                dbf=$dir/installation/sql/mysql/add-admin.sql

                set_file $dbf 'INSERT INTO `'$db_name'`.`jos_users` (`id`, `name`, `username`, `email`, `password`, `block`, `sendEmail`, `registerDate`, `lastvisitDate`, `activation`, `params`, `lastResetTime`, `resetCount`, `otpKey`, `otep`, `requireReset`)'" VALUES ('939', 'Super User', 'admin', 'root@localhost', MD5('$password'), '0', '1', CURRENT_DATE(), CURRENT_DATE(), '0', '', CURRENT_DATE(), '0', '', '', '0');
"'INSERT INTO `jos_user_usergroup_map` (`user_id`,`group_id`) '"VALUES ('939','8');"

                cat $dbf
                mysql $MDA -e "USE $db_name; source $dbf;"

                rm -rf $dir/installation
                
                echo $password > $dir/.admin
                chmod 000 $dir/.admin

                systemctl restart httpd.service
                
                log "Joomla! installed. https://"$(hostname)"/$URI/administrator admin:$password"

        ok
        fi ## install-joomla


fi

man '
    Use the github release of Joomla! Create configuration files.
    http://www.joomla.org/
'


