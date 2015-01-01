#!/bin/bash

if $onHS
then ## no identation.


## start
hint "start VE" "Start a container."
if [ "$CMD" == "start" ]
then
	set_file_limits
	
	argument C	

	rm -rf $SRV/$C/disabled

	set_is_running
	
	if [ ! -f $SRV/$C/disabled ] && ! $is_running
	then
		lxc-start -o $SRV/$C/lxc.log -n $C -d
		printf ${yellow}"%-10s"${NC} "STARTED"	
		get_info
		wait_for_ve_connection $C
		nfs_share
	else
		get_state
		get_info
		echo ''
	fi	
	

ok
fi

## startall
hint "start-all" "Start all containers and services."
if [ "$CMD" == "start-all" ]
then

	set_file_limits

	for C in $(lxc-ls)
	do


		set_is_running
	
		if [ ! -f $SRV/$C/disabled ] && ! $is_running
		then
			lxc-start -o $SRV/$C/lxc.log -n $C -d
			printf ${yellow}"%-10s"${NC} "STARTED"	
			get_info
			wait_for_ve_connection $C
			nfs_share
		else
		  	get_state
			get_info
			echo ''
		fi	


	

	done

ok
fi

fi
