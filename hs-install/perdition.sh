## IMAP4S proxy
if [ ! -f /etc/perdition/perdition.conf ] || $all_arg_set
then

        log "Install perdition, with custom service files: imap4.service, imap4s.service, pop3s.service"

        pm perdition
        ##   + vanessa_logger vanessa_socket

        ## perdition is run as template.service by default.
        ## we use our own unit files and service names.

cat $ssl_pem > /etc/perdition/crt.pem
cat $ssl_key > /etc/perdition/key.pem

ssl_cab_hasbang='#'
if [ -f $ssl_cab ]
then
    ssl_cab_hasbang=''
    cat $ssl_cab > /etc/perdition/ca-bundle.pem
fi


        set_file /etc/perdition/perdition.conf '#### srvctl tuned perdition.conf
## Logging settings


# Turn on verbose debuging.
#debug
#quiet


# Log all comminication recieved from end-users or real servers or sent from perdition.
# Note: debug must be in effect for this option to take effect.


connection_logging


log_facility mail


## Basic settings


## NOTE: possibly listen only on the external-facing interface, and local-dovecot only on 127.0.0.1
bind_address 0.0.0.0 


domain_delimiter @




#### IMPORTANT .. the symbolic link .so.0 does not work. Full path is needed to real file.
map_library /usr/lib64/libperditiondb_posix_regex.so.0.0.0
map_library_opt /etc/perdition/popmap.re


no_lookup


ok_line "Reverse-proxy IMAP4S service lookup OK!"


## If no matches found in popmap.re
outgoing_server localhost


strip_domain remote_login


## For the default dovecot config, no ssl verification is needed
ssl_no_cert_verify
ssl_no_cn_verify


ssl_no_cn_verify


## SSL files
ssl_cert_file /etc/perdition/crt.pem
ssl_key_file /etc/perdition/key.pem
'$ssl_cab_hasbang'ssl_ca_chain_file /etc/perdition/ca-bundle.pem

'
## TODO check if chainfile is needed

        set_file /etc/perdition/popmap.re '#### srvctl tuned popmap.re


# (.*)@'$HOSTNAME': localhost


## you may add email domains here that should be located at localhost.


(.*)@(.*): $2
'

## srvctl custom unit files to make it work with different pid files.

mkdir -p /var/run/perdition

set_file /usr/lib/systemd/system/imap4.service '[Unit]
Description=Perdition IMAP4 reverse proxy
After=syslog.target network.target


[Service]
Type=forking
PIDFile=/var/run/perdition/perdition-imap4.pid
EnvironmentFile=-/etc/sysconfig/perdition
ExecStart=/usr/sbin/perdition.imap4 --pid_file /var/run/perdition/perdition-imap4.pid --protocol IMAP4 --ssl_mode tls_outgoing --bind_address 127.0.0.1


[Install]
WantedBy=multi-user.target
'

set_file /usr/lib/systemd/system/imap4s.service '[Unit]
Description=Perdition IMAP4S reverse proxy
After=syslog.target network.target


[Service]
Type=forking
PIDFile=/var/run/perdition/perdition-imap4s.pid
EnvironmentFile=-/etc/sysconfig/perdition
ExecStart=/usr/sbin/perdition.imap4s --pid_file /var/run/perdition/perdition-imap4s.pid --protocol IMAP4S


[Install]
WantedBy=multi-user.target
'

set_file /usr/lib/systemd/system/pop3s.service '[Unit]
Description=Perdition POP3S reverse proxy
After=syslog.target network.target


[Service]
Type=forking
PIDFile=/var/run/perdition/perdition-pop3s.pid
EnvironmentFile=-/etc/sysconfig/perdition
ExecStart=/usr/sbin/perdition.pop3s --pid_file /var/run/perdition/perdition-pop3s.pid --protocol POP3S


[Install]
WantedBy=multi-user.target
'



        add_service imap4
        add_service imap4s    
        add_service pop3s

        
        systemctl daemon-reload
        
else
    msg "Perdition is already installed."
fi ## install perdition

