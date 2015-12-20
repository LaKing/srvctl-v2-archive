if $onHS && $isROOT
then 
## no identation.
        hint "mkcert DOMAIN" "Create an SSL certificate."
        if  [ "$CMD" == "mkcert" ]
        then
            argument D
            
        if ! $(is_fqdn $D)
        then
          err "$D failed the domain regexp check. Exiting."
          exit 10
        fi
              
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
        net    ipv6
        dns    zone
        git    repo
        src    source
        srv    service
        lab    label
        doc    docs
        dyn    dyndns
        ftp    files
        adm    admin
        alt    port
        opt    custom
        org    info
        vnc    container
        vpn    network
        gui    devel
        
    Additional labels:
                webmail
                shop
                forum
                demo
                chat        
                
        .. feel free to submit suggestions on github.
'
fi

#eof

