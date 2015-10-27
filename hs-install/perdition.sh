## To create proper SMTPD Auth proxy method http://www.postfix.org/SASL_README.html
## saslauthd can verify the SMTP client credentials by using them to log into an IMAP server. 
## If the login succeeds, SASL authentication also succeeds. saslauthd contacts an IMAP server when started like this: saslauthd -d -a rimap -O test.d250.hu
## the remote server - in the container - needs to have dovecot (or an IMAP server) with users to authenticate.

## saslauthd and perdition - incompability problem as of 2014.06.25 
## 
## saslauthd with rimap to perdition ...
## The response after LOGIN is not being processed correctly.
## Perdition sends the CAPABILITY before the OK, thus saslauthd returns 
## [reason=[ALERT] Unexpected response from remote authentication server] 
## .. and fails to authenticate.
##
## A workaround is to patch saslauthd.
## We can consider CAPABILITY equal to OK [CAPABILITY ...], as in case of bad password / bad username / bad host, the remote server rejects the credentials.
## That means, if the response is not a NO, and there is a response, we can assume its an OK.
##
## cyrus-sasl-2.1.26/saslauthd/auth_rimap.c last lines:
## replace: return strdup(RESP_UNEXPECTED);
## with: return strdup("OK remote authentication successful"); 
## .. compile, install.
##
## Some more dev-hints.
##
## The LOGIN command is supported on both, saslauthd and perdition, plaintext only on saslauthd.
## Here is a note how to enable plaintext in dovecot:
## disable_plaintext_auth = no  >>> /etc/dovecot 10-auth.conf 
## ssl = no >>> 10-ssl.conf 
## testing the running saslauthd: testsaslauthd -u tx -p xxxxxx
##
## Get base64 encoded login code for user x pass xxxxxx
## echo -en "\0x\0xxxxxx" | base64
## AHgAeHh4eHh4
##
##
## Send e-mail
## echo "this is the body" | mail -s "this is the subject" "to@address"
##
## Other test commands:
##
#### plaintext IMAP connaction test
## telnet test.d250.hu 143
## a AUTHENTICATE PLAIN
## + base64_code
##
#### IMAP4S connection test
## openssl s_client -crlf -connect test.d250.hu:993
## a LOGIN user passwd
##
#### SASL commands
## saslauthd -a rimap -O localhost
## saslauthd -d -a rimap -O localhost
## testsaslauthd -u username -p password
## testsaslauthd -u x -p xxxxxx
## testsaslauthd -u x@test.d250.hu -p xxxxxx
##
#### SMTPS connection test 
## openssl s_client -connect test.d250.hu:465
## EHLO d250.hu
## AUTH PLAIN
## base64_code
##
## exit from telnet Ctrl-AltGr-G quit
##
## TODO: this information is submitted to the cyrus sasl devel mailing list. keep an eye on it.
## for now we will aply a customization in the next step.

## to verify openssl SNI use the following command:
## openssl s_client -servername container.ve -connect localhost:443

## IMAP4S proxy
if [ ! -f /etc/perdition/perdition.conf ] || $all_arg_set
then

        log "Install perdition, with custom service files: imap4.service, imap4s.service, pop3s.service"

        pm perdition
        ##   + vanessa_logger vanessa_socket

        ## perdition is run as template.service by default.
        ## we use our own unit files and service names.

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

#ssl_ca_chain_file /etc/perdition/ca-bundle.pem
'
## TODO check if chainfile is needed

        set_file /etc/perdition/popmap.re '#### srvctl tuned popmap.re

# (.*)@'$(hostname)': localhost

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

set_file /etc/sasl2/smtpd.conf 'pwcheck_method: saslauthd
mech_list: LOGIN'


        cat /root/ca-bundle.pem > /etc/perdition/ca-bundle.pem
        cat /root/crt.pem > /etc/perdition/crt.pem
        cat /root/key.pem > /etc/perdition/key.pem

        ## saslauthd
        if ! diff /root/saslauthd /usr/sbin/saslauthd >/dev/null ; then
                 rm -fr /usr/sbin/saslauthd
                cp /root/saslauthd /usr/sbin/saslauthd
                chmod 755 /usr/sbin/saslauthd
                saslauthd -v
        fi

        bak /etc/sysconfig/saslauthd

        set_file /etc/sysconfig/saslauthd '# Directory in which to place saslauthds listening socket, pid file, and so
# on.  This directory must already exist.
SOCKETDIR=/run/saslauthd

# Mechanism to use when checking passwords.  Run "saslauthd -v" to get a list
# of which mechanism your installation was compiled with the ablity to use.
MECH=rimap

# Additional flags to pass to saslauthd on the command line.  See saslauthd(8)
# for the list of accepted flags.
FLAGS="-O localhost -r"'

        systemctl daemon-reload

        systemctl stop imap4.service
        systemctl enable imap4.service
        systemctl start imap4.service
        systemctl status imap4.service

        systemctl stop imap4s.service
        systemctl enable imap4s.service
        systemctl start imap4s.service
        systemctl status imap4s.service

        systemctl stop pop3s.service
        systemctl enable pop3s.service
        systemctl start pop3s.service
        systemctl status pop3s.service

        systemctl stop saslauthd.service
        systemctl enable saslauthd.service
        systemctl start saslauthd.service
        systemctl status saslauthd.service
else
    msg "Perdition is already installed."
fi ## install perdition

