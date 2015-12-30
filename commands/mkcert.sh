if $onHS && $isROOT
then 
## no identation.
        hint "create-certificate DOMAIN" "Create an SSL certificate."
        if  [ "$CMD" == "create-certificate" ]
        then
            argument D
            
        if ! $(is_fqdn $D)
        then
          err "$D failed the domain regexp check. Exiting."
          exit 10
        fi
                cert_path=/etc/srvctl/cert/$D
                create_certificate $D
            
        ok
        fi

man '
Generate key, make a csr, self sign it. It can be signed by a certificate authority as well.
Certificates will reside in /etc/srvctl/cert/DOMAIN 
    Note for signing SAN wildcard certificates with a CA. Srvctl is mapping / can map container ports to domain names.
    It is possible to have wildcard certificates for *.service.domain.net and *.label.domain.net
    Since srvctl maps certain applications default ports to subdomain names it is recommended to keep the following list of active and possibly future services and labels.
    
    Labels:    Services:
        www    test
        web    stage
        dev    codepad
        run    play
        log    logio
        ssh    shell
        sys    cockpit
        dns    zone
        git    repo
        src    source
        srv    service
        lab    label
        doc    docs
        dyn    dyndns
        ftp    files
        adm    admin
        pma    phpmyadmin
        alt    port
        opt    custom
        vnc    container
        vpn    network
        gui    devel
        wss    websocket
        
    Additional labels:
                webmail
                shop
                forum
                demo
                chat
                game        
                support
        .. feel free to submit suggestions on github.
'
fi

## server names might be two letter codes for quick access.
## but they should not interfer with top level domains
## easy r2 bp c4 f6
## hard pm sc gb db


