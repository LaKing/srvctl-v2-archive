#!/bin/bash

if $onHS
then ## no identation.


## stop
hint "stop VE" "Stop a container." 
hint "disable VE" "Stop and diable container." 
if [ "$CMD" == "stop" ] || [ "$CMD" == "disable" ]
then

	argument C

	nfs_unmount

	set_is_running

	if $is_running
	then
		printf ${yellow}"%-10s"${NC} "SHUTDOWN"
		get_info
		nfs_unmount
		ssh $C shutdown -P now
	else 
		get_state
		get_info
	fi

	
	if [ "$CMD" == "disable" ]
	then
		echo $NOW > $SRV/$C/disabled
	fi
	echo ''		

ok
fi ## stop

## stop-all
hint "stop-all" "Stop all containers." 
if [ "$CMD" == "stop-all" ]
then
	for C in $(lxc-ls)
	do

		nfs_unmount

		set_is_running

		if $is_running
		then
			printf ${yellow}"%-10s"${NC} "SHUTDOWN"
			get_info
			nfs_unmount
			ssh $C shutdown -P now
		else 
			get_state
			get_info
		fi

		echo ''	

	done	

ok
fi ## stop-all

fi
