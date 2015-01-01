#!/bin/bash

test_mariadb=$(systemctl is-active mariadb.service)

###
###	MariaDB related client-functions
###

function check_mariadb_connection {

	mysql $MDA -e exit 2> /dev/null

	if [ "$?" -ne 0 ]
	then
		err 'CONNECTION FAILED'
		exit
	else
		msg '.. mysql connected'
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
		fi

	else
		MDA="-u root"
	fi

	mysql $MDA -e exit 2> /dev/null

	if [ "$?" -ne 0 ]
	then
		msg '.. connected to mysql / mariadb'

		if [ "$MDA" == "-u root" ]
		then
		msg "Securing ..."

	 	mysql $MDA -e "DELETE FROM mysql.user WHERE User='';"
		mysql $MDA -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
		mysql $MDA -e "DROP DATABASE IF EXISTS test;"

		get_password
	
		SQL="UPDATE mysql.user SET Password=PASSWORD('$password') WHERE User='root'; flush privileges;"
		mysql $MDA -e "$SQL"
			
			if [ "$?" -ne 0 ]
			then
				log "Set database root password to: "$password

				bak $MDF

				## set up backup params
				echo '[client]' > $MDF
				echo 'user=root' >> $MDF
				echo 'password='$password >> $MDF
			fi
		fi

	fi
}


## Add new database
function add_mariadb_db {

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

	SQL="GRANT ALL ON $db_name.* TO '$db_usr'@'localhost' IDENTIFIED BY '$db_pwd'; flush privileges;"
	ntc "$SQL"
	mysql $MDA -e "$SQL"

	## save these params to etc
	f=/etc/mysqluser.conf
	echo "dbf:"$db_name >> $f
	echo "usr:"$db_usr >> $f
	echo "pwd:"$db_pwd >> $f
	
	msg "Added MariaDB database $db_name  $db_usr:$db_pwd"
}



