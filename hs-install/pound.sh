if [ ! -f /etc/pound.cfg ] || $all_arg_set
then

        msg "Installing Pound"
        ## Pound is a reverse Proxy for http / https
        pm Pound

set_file /etc/pound.cfg '## srvctl pound.cfg
User "pound"
Group "pound"
Control "/var/lib/pound/pound.cfg"

## Default loglevel is 1
LogFacility local0
LogLevel    2

Alive 1

ListenHTTP

    Address 0.0.0.0
    Port    80

    Err414 "/var/www/html/414.html"
    Err500 "/var/www/html/500.html"
    Err501 "/var/www/html/501.html"
    Err503 "/var/www/html/503.html"

    Include "/var/pound/http-includes.cfg"

End
ListenHTTPS

    Address 0.0.0.0
    Port    443

    Err414 "/var/www/html/414.html"
    Err500 "/var/www/html/500.html"
    Err501 "/var/www/html/501.html"
    Err503 "/var/www/html/503.html"

    ## The certificate from root.
    Cert "/etc/pound/pound.pem"
    
    ## CA certificates - gives error: SSL_CTX_use_PrivateKey_file failed - aborted
    #Cert "/etc/pki/ca-trust/extracted/openssl/ca-bundle.trust.crt"

    Include "/var/pound/https-includes.cfg"

End

## Include the default host here, as a fallback.
# Include "/srv/default-host/pound"
'
        ## certificate chainfile
        mkdir -p /etc/pound
        

        cat /root/crt.pem > /etc/pound/crt.pem
        cat /root/key.pem > /etc/pound/key.pem
        cat /root/ca-bundle.pem > /etc/pound/ca-bundle.pem 2> /dev/null

        cat /root/crt.pem > /etc/pound/pound.pem
        echo '' >> /etc/pound/pound.pem
        cat /root/key.pem >> /etc/pound/pound.pem
        echo '' >> /etc/pound/pound.pem
        cat /root/ca-bundle.pem >> /etc/pound/pound.pem 2> /dev/null


        mkdir -p /var/pound
        mkdir -p /var/www/html

        #  echo $MSG >> /etc/srvctl/pound-include-ca.cfg
        #  echo 'CAlist "/etc/srvctl/ca-bundle.pem"' >> /etc/srvctl/pound-include-ca.cfg
        ## TODO check for /etc/pki maybe?

        ## The pound-served custom error documents

set_file /var/www/html/414.html '<head></head><body bgcolor="#333"><div id="header" style="background-color:#151515;"><img src="http://'$CDN'/logo.png" alt="'"$CMP"'" style="display: block; margin-left: auto; margin-right: auto; vertical-align: middle"></div><p align="center"><font color="#aaa" style="margin-left: auto; margin-right: auto" size="6px" face="Arial">
<b>Error 414</b> @ '$HOSTNAME'<br />
Request URI is too long.
</font><p></body>'

set_file /var/www/html/500.html '<head></head><body bgcolor="#333"><div id="header" style="background-color:#151515;"><img src="http://'$CDN'/logo.png" alt="'"$CMP"'" style="display: block; margin-left: auto; margin-right: auto; vertical-align: middle"></div><p align="center"><font color="#aaa" style="margin-left: auto; margin-right: auto" size="6px" face="Arial">
<b>Error 500</b> @ '$HOSTNAME'<br />
An internal server error occurred. Please try again later.
</font><p></body>'

set_file /var/www/html/501.html '<head></head><body bgcolor="#333"><div id="header" style="background-color:#151515;"><img src="http://'$CDN'/logo.png" alt="'"$CMP"'" style="display: block; margin-left: auto; margin-right: auto; vertical-align: middle"></div><p align="center"><font color="#aaa" style="margin-left: auto; margin-right: auto" size="6px" face="Arial">
<b>Error 501</b> @ '$HOSTNAME'<br />
Request URI is too long.
</font><p></body>'

set_file /var/www/html/503.html '<head></head><body bgcolor="#333"><div id="header" style="background-color:#151515;"><img src="http://'$CDN'/logo.png" alt="'"$CMP"'" style="display: block; margin-left: auto; margin-right: auto; vertical-align: middle"></div><p align="center"><font color="#aaa" style="margin-left: auto; margin-right: auto" size="6px" face="Arial">
<b>Error 503</b> @ '$HOSTNAME'<br />
The service is not available. Please try again later.
</font><p></body>'


        if [ ! -f /var/www/html/favicon.ico ]
        then
           msg "Downloading favicon.ico from $CDN"
           wget -O /var/www/html/favicon.ico http://$CDN/favicon.ico
        fi

        if [ ! -f /var/www/html/logo.png ]
        then
           msg "Downloading logo.png from $CDN" 
           wget -O /var/www/html/logo.png http://$CDN/logo.png
        fi

        if [ ! -f /var/www/html/favicon.ico ]
        then
           err "No favicon.ico from could be located."
        fi

        if [ ! -f /var/www/html/logo.png ]
        then
           err "No logo.png from could be located."
        fi

## Pound logging. By default pound is logging to systemd-journald.
## To work with logs, use rsyslog to export to /var/log/pound

        pm rsyslog

        add_conf /etc/rsyslog.conf 'local0.*                         -/var/log/pound'

        systemctl restart rsyslog.service


        systemctl stop pound.service
        systemctl enable pound.service
        systemctl start pound.service
        systemctl status pound.service

else
    msg "Pound config found."
fi ## install pound

