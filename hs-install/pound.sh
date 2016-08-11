setup_varwwwhtml_error 414 "Request URI too long!"
setup_varwwwhtml_error 500 "An internal server error occurred. Please try again later."
setup_varwwwhtml_error 501 "This method may not be used."
setup_varwwwhtml_error 503 "The service is not available. Please try again later."


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


## Pound logging. By default pound is logging to systemd-journald.
## To work with logs, use rsyslog to export to /var/log/pound

        pm rsyslog

        add_conf /etc/rsyslog.conf 'local0.*                         -/var/log/pound'

        systemctl restart rsyslog.service


        add_service pound

else
    msg "Pound config found."
fi ## install pound




