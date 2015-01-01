#!/bin/bash

if $onHS
then ## no identation.

## regenerate configs 
hint "regenerate [all]" "Regenerate configuration files, and restart affected services."
if [ "$CMD" == "regenerate" ]
then

	if [ "$2" == "all" ]
	then
	   all_arg_set=true
	fi

	regenerate_counter

	regenerate_config_files

	regenerate_etc_hosts 

	regenerate_known_hosts

	regenerate_pound_files

	regenerate_root_configs

	regenerate_users 

	regenerate_users_configs

	regenerate_users_structure

	regenerate_dns

	regenerate_logfiles
	
	
ok
fi ## regenerate

fi
