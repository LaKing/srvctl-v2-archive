if $onHS && $isROOT
then ## no identation.

## regenerate configs 
hint "regenerate [all]" "Regenerate configuration files, and restart affected services. (!)"
if [ "$CMD" == "regenerate" ] || [ "$CMD" == "regenerate-all" ] || [ "$CMD" == "!" ]
then

        if [ "$CMD" == "regenerate-all" ] || [ "$ARG" == "all" ]
        then
            all_arg_set=true
        fi
            
            ## counter linearly assigns a unique number to containers.
            regenerate_counter

            ## for each container generate_lxc_config
            regenerate_config_files
        
            ## /etc/hosts for trusted localhosts
            regenerate_etc_hosts 
        
            ## for each container scan_host_key
            regenerate_known_hosts

            ## query 8.8.8.8 for dns information
            regenerate_dns_publicinfo
            
            ## for each container import certificates
            regenerate_letsencrypt
        
            ## create pound configuration files
            regenerate_pound_files
            
            ## perdition configs
            regenerate_perdition_files

            ## ssh related
            regenerate_root_configs
        
            ## add_user(s)
            regenerate_users 
        
            ## for each user generate_user_configs
            regenerate_users_configs
        
            ## for each user generate_user_structure
            regenerate_users_structure
            
            ## share of server data with containers
            regenerate_var_ve
            
            ## opendkim for email signing
            regenerate_opendkim
            
            ## bind / named configs
            regenerate_dns
            
            ## hostname and srvctl-hosts configs
            regenerate_hosts_config
            
            ## make logfiles for apache log - kind of cosmetic action
            regenerate_logfiles
            
            ## kind of unnecessery, but since the commands are developed actively its here for now.
            regenerate_sudo_configs
            

               
ok
fi ## regenerate

man '
    In case some srvctl configuration files, or data files are changed, it is required to regenerate runtime configurations.
    Configuration files are mostly located in /root/srvctl-users and /srv/VE/ but data may reside in users home folders.
    For all critical configuration files .bak backup files will be created. Regenerated important system configuration files include:
    /etc/hosts, /etc/relydomains, etc, ...
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


