#!/bin/bash

if $onHS
then ## no identation.


## reMOVE host
hint "remove VE" "Remove a container."
if [ "$CMD" == "remove" ]
then

	argument C 

	nfs_unmount

	lxc-stop -k -n $ARG

	## remove from known_hosts ... regenerate?

	RMD=$TMP/$C-$NOW
	mkdir -p $RMD

	if [ -d "$SRV/$C" ]; then
		log "Removing container to $RMD"

		rsync -a $SRV/$C $RMD
		rm -fr $SRV/$C

		## delete each users share.
		for _U in $(ls /home)
		do
			if [ -d "/home/$_U/$C" ]
			then
				## take care of password hash
				rm -rf /home/$_U/$C/mnt/.password.sha512
				
				## remove mnt folder - if empty
				if [ -z "$(ls /home/$_U/$C/mnt 2> /dev/null)" ]
				then
					rm -rf /home/$_U/$C/mnt
				fi

				## remove user container folder
				if [ -z "$(ls /home/$_U/$C )" ]
				then
					rm -rf /home/$_U/$C
				fi
			fi
		done

		## TODO regenerate everything
		regenerate_etc_hosts
		regenerate_known_hosts
		regenerate_pound_files
		regenerate_dns
		regenerate_logfiles
	else
		msg "Could not remove $C - no such VE."
	fi

ok
fi ## reMOVE

fi
