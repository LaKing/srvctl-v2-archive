#!/bin/bash

test_mariadb=$(systemctl is-active mariadb.service)

###
###        MariaDB related client-functions
###

function check_mariadb_connection {
    
        if [ -f "$MDF" ]
        then
            MDA="--defaults-file=$MDF -u root"
        else
            MDA="-u root"
        fi
        
        mysql $MDA -e exit 2> /dev/null

        if [ "$?" -ne 0 ]
        then
                err "CONNECTION FAILED to mariadb $MDA"
                exit
        else
                msg ".. mysql connected"
        fi
}

function setup_mariadb {

        ## Main purpose of this function is to set up $MDA the mysql 
                
        test_mariadb=$(systemctl is-active mariadb.service)
        if [ ! "$test_mariadb" == "active" ]
        then

                ## TODO connection check
                msg "Install Mysql/MariaDB."        
                yum -y install mariadb-server
                systemctl enable mariadb.service
                systemctl start mariadb.service

                systemctl status mariadb.service

        fi
        
}

function secure_mariadb {
    
        setup_mariadb
    
        ## Decide if mysql is secured, and has a defaults-file
        if [ -f "$MDF" ]
        then
                MDA="--defaults-file=$MDF -u root"

                ## check_mariadb_connection

                mysql $MDA -e exit 2> /dev/null

                if [ "$?" -ne 0 ]
                then
                        err 'CONNECTION FAILED using '$MDF
                        MDA="-u root"
                        
                        mysql $MDA -e exit 2> /dev/null
        
                        if [ "$?" -ne 0 ]
                        then
                            err 'CONNECTION FAILED without password'
                        else
                            err "CONNECTED without password, and not with $MDF"
                        fi    
                        
                else
                        msg "CONNECTION to mysql is OK"
                fi
                


        else
        
            MDA="-u root"
            mysql $MDA -e exit 2> /dev/null

            if ! [ "$?" -ne 0 ]
            then
                msg 'CONNECTED to mysql / mariadb - securing.'
                
                get_password
                
                ## set up backup params
                echo '[client]' >> $MDF
                echo 'user=root' >> $MDF
                echo 'password='$password >> $MDF

                mysql $MDA -e "DELETE FROM mysql.user WHERE User='';"
                mysql $MDA -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
                mysql $MDA -e "DROP DATABASE IF EXISTS test;"
                
                SQL="UPDATE mysql.user SET Password=PASSWORD('$password') WHERE User='root'; flush privileges;"
                mysql $MDA -e "$SQL"
                        
                        if ! [ "$?" -ne 0 ]
                        then
                            log "Set database root password to: "$password
                        else
                            err "CONNECTION FAILED. Could not set mariadb password, ..."
                        fi
            else
                err "CONNECTION FAILED Could not secure mysql, could not connect as root."
            fi
        fi
}


## Add new database
function add_mariadb_db {
    
        check_mariadb_connection
        
        ## input $dbd database-definition - basically the database name.
        ## $MDA MaridaDB / MysqlDatabase - Argument        

        if [ -z "$dbd" ]
        then
                        if [ -z "$1" ]
                        then
                                dbd=$(cat /etc/hostname)
                        else
                                dbd=$1
                        fi
        fi
        
        dbd=$(echo $dbd | tr '.' '_' | tr '-' '_')

        get_password
        db_usr=${dbd:0:15}
        db_name=${dbd:0:63}
        db_pwd=$password

        SQL="CREATE DATABASE IF NOT EXISTS $db_name;"
        ntc "$SQL"
        mysql $MDA -e "$SQL"
        
        if ! [ "$?" -ne 0 ]
        then
            err "CONNECTION FAILED. Could not use mariadb, ... $MDA"
        fi

        SQL="GRANT ALL ON $db_name.* TO '$db_usr'@'localhost' IDENTIFIED BY '$db_pwd'; flush privileges;"
        ntc "$SQL"
        mysql $MDA -e "$SQL"
        
        if ! [ "$?" -ne 0 ]
        then
            err "CONNECTION FAILED. Could not use mariadb, ... $MDA"
        fi

        ## save these params to etc
        f=/etc/mysqluser.conf
        echo "dbf:"$db_name >> $f
        echo "usr:"$db_usr >> $f
        echo "pwd:"$db_pwd >> $f
        
        msg "Added MariaDB database $db_name  $db_usr:$db_pwd"
}




