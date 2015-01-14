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

man '
    In case some srvctl configuration files, or data files are changed, it is required to regenerate runtime configurations.
    Configuration files are mostly located in /root/srvctl-users and /srv/VE/ but data may reside in users home folders.
    For all critical configuration files .bak backup files will be created. Regenerated important system configuration files include:
    /etc/hosts, /etc/relydomains, /root/.ssh/known_hosts, all /home/USER/.ssh/known_hosts, all /home/USER/.ssh/authorized_keys
    NFS shares are mounted if missing. Note, direct mount-shares in /mnt are presistent, and reside in the users /home folders.
    Important srvctl VE configuration files located in the /srv/VE/ folder, used as base-data in the regeneration process include:
        aliases - newline seperated list of domain names that are considered alternate domain names for the container.
        users - newline seperated list of local usernames granted root access to the container. Nonexistent users will be created.
        pound-host - the primary hostname for the host used in the web-hosting. Pound is the reverse proxy used in srvctl.
        pound-http-port, pound-https-port - defines what ports of the VE should be served on the http / https port of the host.
        pound-http-service-directives, pound-https-service-directives - additional pound BackEnd configuration directives
        pound-enable-altdomain - A container may have one alternate domain name defined in that file, serving a different content.
        pound-altdomain-http-port, pound-altdomain-https-port - for the alternative domain, custom ports should be defined.
        pound-altdomain-http-service-directives, pound-altdomain-https-service-directives - pound BackEnd configuration directives.
        pound-enable-dev - if file is present, codepad VE configuration is set for pound. Port 9001 is forwarded on the dev. subdomain.
        pound-enable-log - if file is present, logio VE configuration is set for pound. Port 9003 is forwarded on the log. subdomain.
        pound-no-http - if file is present, all http requests are redirected to https by pound
        pound-no-https - if file is present, all https requests are redirected to http by pound
        pound-redirect - redirect all http and https requests to the domain name entry in that file 
        disabed - if that file is present, the container is considered diabled and wont be started by srvctl.
    Additionally, adding signed certificates to /srv/VE/cert requires a regeneration too. Certificates are checked for validity. 
'

fi
