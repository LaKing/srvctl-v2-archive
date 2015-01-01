#!/bin/bash

## disabled command

if $onHS && $debug
then ## no identation.

hint "reset-install" "!!!"
## This is mainly for dev! This should be disabled in production!
if [ "$CMD" == "reset-install" ]
then

	### As I said, ONLY if you really need this.
	#log "WARNING! Command disabled."
	#exit

	for C in $(ls $SRV)
	do
		lxc-stop -k -n $C
	done

	rm -rf $SRV/*
	# rm -rf /root/.ssh/known_hosts
	rm -rf /etc/srvctl
	rm -rf /root/srvctl
	rm -rf /var/srvctl

	systemctl stop pound.service

	echo '127.0.0.1		localhost.localdomain localhost' > /etc/hosts
	echo '::1		localhost6.localdomain6 localhost6' >> /etc/hosts

	echo 'DONE!'

ok
fi

fi
