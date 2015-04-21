#!/bin/bash

if $onVE
then ## no identation.

## To delete all backups older then 10 days 
##  find $BACKUP_POINT -type d -mtime +4 | xargs rm -rf

if [ "$test_mariadb" == "active" ]
then
          

        setup_mariadb

        hint "mysql [CMD..]" "Enter mariadb/mysql as root, or execute SQL command."
        if  [ "$CMD" == "mysql" ]
        then
                if [ -z "$2" ]
                then
                        mysql $MDA
                else
                        mysql $MDA -e "$2" 
                fi 
        ok
        fi

        hint "import-db DATABASE" "Import a mysql database."
        if [ "$CMD" == "import-db" ] 
        then

                argument db
                
                ## TODO check if file exists

                mysql $MDA < $db

                mysql $MDA -e "show databases;"

        ok
        fi ## import db



        hint "add-db DATABASE" "Add a new database."
        if [ "$CMD" == "add-db" ] 
        then
                #MDA="--defaults-file=$MDF -u root"

                argument db_name

                get_password

                db_usr=$db_name 
                db_pwd=$password

                SQL="CREATE DATABASE IF NOT EXISTS $db_name"
                ntc "$SQL"
                mysql $MDA -e "$SQL"


                SQL="GRANT ALL ON *.* TO '$db_usr'@'localhost' IDENTIFIED BY '$db_pwd'; flush privileges;"
                ntc "$SQL"
                mysql $MDA -e "$SQL"

                ## save these params
                conf=/etc/mysqluser.conf
                echo 'dbf:'$db_name >> $conf
                echo 'usr:'$db_usr >> $conf
                echo 'pwd:'$db_pwd >> $conf


        ok
        fi ## add-db


        hint "reset-db-root-passwd" "Reset Database root password."
        if [ "$CMD" == "reset-db-root-passwd" ] 
        then

                get_password

                test=$(mysql $MDA -e "show databases" | grep Database)

                if [ "$test" == "Database" ] 
                then
                        msg "The database is accessible."
                else
                        msg "Could not enter database! "

                        systemctl stop mysqld.service
                        sleep 1
                        mysqld_safe --skip-grant-tables &
                        sleep 10

                        test=$(mysql $MDA -e "show databases" | grep Database)
                        if [ "$test" == "Database" ] 
                        then
                                msg "Re-entered database in safe mode."
                        else
                                err "Could not re-enter mysql!"
                                exit
                        fi

                fi

                log "Set MariaDB database root password to: $password"
                SQL="UPDATE mysql.user SET Password=PASSWORD('$password') WHERE User='root'; flush privileges;"
                mysql $MDA -e "$SQL"


                ## set up backup params
                bak $MDF

                echo '[client]' > $MDF
                echo 'user=root' >> $MDF
                echo 'password='$password >> $MDF

                msg "Rebooting the container."
                reboot

        ok
        fi ## reset-db-root-password

        hint "backup-db [clean]" "Create a backup of the Mysql/MariaDB database, Optionally clean older backups."
        if [ "$CMD" == "backup-db" ] 
        then

                log "Creating backup of Mysql/Mariadb databases."

                old_backup=$(ls -d /srv/backup-db/* 2> /dev/null)

                BACKUP_POINT="/srv/backup-db/"$(date +%Y_%m_%d__%H_%M_%S)
                mkdir -p $BACKUP_POINT

                ## All Databases into a single file?
                # mysqldump $MDA --all-databases >$BACKUP_POINT/all-databases.sql

                succ=1
                ## create backup for each database
                for i in `echo "show databases" | mysql $MDA | grep -v Database`; do 
                    if [ "$i" != "information_schema" ] && [ "$i" != "performance_schema" ] 
                    then 
                    mysqldump $MDA --databases $i > $BACKUP_POINT/$i.sql
                    if [ "$?" -eq 0 ]
                     then
                                msg "OK:   "$i
                        else
                                 err "ERROR "$i
                                 succ=0
                        fi
                    fi
                done

                if [ $succ -gt 0 ]
                then
                    msg 'All databases have a backup in '$BACKUP_POINT

                    if [ "$2" == "clean" ]
                    then
                     rm -fr $old_backup
                    fi
                fi
        ok
        fi ## backup db

        hint "add-phpmyadmin" "Set up phpmyadmin."
        if [ "$CMD" == "add-phpmyadmin" ] 
        then

                yum -y install php
                yum -y install phpmyadmin


                ## grant access.
                ## This will grant passwordless setup!                
                #sed_file /etc/httpd/conf.d/phpMyAdmin.conf "       Require ip 127.0.0.1" "       Require all granted"
                #sed_file /etc/httpd/conf.d/phpMyAdmin.conf "       Require ip ::1" "       #Require ip ::1"

                ## instead, use this custom conf for Apache 2.4
                set_file /etc/httpd/conf.d/phpMyAdmin.conf "# phpMyAdmin - Web based MySQL browser written in php

                Alias /phpMyAdmin /usr/share/phpMyAdmin
                Alias /phpmyadmin /usr/share/phpMyAdmin

                <Directory /usr/share/phpMyAdmin/>
                   <IfModule mod_authz_core.c>
                     <RequireAny>
                       Require all granted
                     </RequireAny>
                   </IfModule>
                </Directory>

                <Directory /usr/share/phpMyAdmin/setup/>
                   <IfModule mod_authz_core.c>
                     # Apache 2.4
                     <RequireAny>
                       Require ip ::1
                     </RequireAny>
                   </IfModule>
                </Directory>
                "
                
                
                ## set params in php.ini, ...          
                sed_file /etc/php.ini ";date.timezone =" "date.timezone = $php_timezone"
                sed_file /etc/php.ini  "upload_max_filesize = 2M" "upload_max_filesize = 25M" 
                sed_file /etc/php.ini  "post_max_size = 8M" "post_max_size = 25M"                
                
                
                systemctl restart httpd.service
        ok
        fi


else

        hint "install-mariadb" "install MariaDB (mysql) database."
        if [ "$CMD" == "install-mariadb" ] 
        then        

                setup_mariadb
        ok
        fi ## setup mariadb
        
        if [ "$CMD" == "backup-db" ] 
        then        
             msg "Maria-db inactive."
        ok
        fi 

fi ## MariaDB related fuctions
fi

man '
    To have an easy life with mysql / mariadb, srvctl detects an active server instance, and offers some basic, and advanced commands.
    Import or create databases, backup databases, and reset passwords. The mysql root password is stored locally, for all operations.
    PhpMyAdmin can be installed for graphical administration. 
'
