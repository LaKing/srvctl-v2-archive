if $onHS
then ## no identation.

## add new dyndns domain
hint "add-dyndns HOSTNAME" "Add new domain as dyndns entry."
if [ "$CMD" == "add-dyndns" ]
then
    argument dyndnshost
    sudomize
    ## verify hostname
    if [ -f /var/dyndns/$dyndnshost.auth ]
    then
        err "$dyndnshost already exists"
        exit
    fi
    
    if [ -d $SRV/$dyndnshost ]
    then
        err "$dyndnshost already exists as container"
        exit
    fi
    
    if [ -f /var/named/srvctl/$dyndnshost.zone ] || [ -f /var/named/srvctl/$dyndnshost.slave ]
    then
        err "$dyndnshost already exists in the DNS"
        exit
    fi
    
    get_password
    
    dyndnspass=$SC_USER:$password
    
    mkdir -p /var/dyndns
    chown node:node /var/dyndns
    chmod 750 /var/dyndns
    
    echo -n $dyndnspass > /var/dyndns/$dyndnshost.auth
    chown node:node /var/dyndns/$dyndnshost.auth
    chmod 640 /var/dyndns/$dyndnshost.auth
    
    msg "Dyndns POST data for authentication is: $dyndnspass - use the following command to update:"
    echo 'curl -k --data "auth='$dyndnspass'" https://'$HOSTNAME':855/'$dyndnshost
    
    regenerate_dns
ok
fi

fi

man '
    This will create a new DNS entry that can be updated with a simple http call to the host.
    Simply send a POST request with the key returned by this command, and the hostname as URI to update the dyndns record. 
'

