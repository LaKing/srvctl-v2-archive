#!/bin/bash

if $onHS
then ## no identation.


## kill
hint "kill VE" "Force all containers to stop."
if [ "$CMD" == "kill" ]
then
	argument C

	set_is_running

	if $is_running
	then
	  	printf ${yellow}"%-10s"${NC} "KILLING"
		get_info
		nfs_unmount
		lxc-stop -k -n $C
			
	else
		get_state
		get_info
		echo ''	
	fi
ok
fi

## kill-all
hint "kill-all" "Force all containers to stop."
if [ "$CMD" == "kill-all" ]
then

	for C in $(lxc-ls)
	do
		set_is_running

		if $is_running
		then
		  	printf ${yellow}"%-10s"${NC} "KILLING"
			get_info
			nfs_unmount
			lxc-stop -k -n $C
			
		else
			get_state
			get_info
			echo ''	
		fi

	done

ok
fi


fi
