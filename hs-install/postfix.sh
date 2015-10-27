## Postfix
## TODO: keep the original postfix conf as a seperate file

if [ ! -f /etc/postfix/main.cf ] || $all_arg_set
then
        pc=/etc/postfix/main.cf

        if grep -q  '## srvctl postfix configuration directives' $pc; then
         msg "Skipping Postfix configuration, as it seems to be configured."
        else
            log "Installing the Postfix mail subsystem."
            bak $pc

            pm postfix
            sed_file $pc 'inet_interfaces = localhost' '#inet_interfaces # localhost'

                ## append to the default conf
                echo '
## srvctl postfix configuration directives
## RECIEVING

## Listen on ..
inet_interfaces = all

## use /etc/hosts instead of dns-query
lmtp_host_lookup = native
smtp_host_lookup = native
## in addition, this might be enabled too.
# smtp_dns_support_level = disabled

## dont forget to postmap /etc/postfix/relaydomains
relay_domains = $mydomain, hash:/etc/postfix/relaydomains

## SENDING
## SMTPS
smtpd_tls_CAfile =    /etc/pki/ca-trust/extracted/openssl/ca-bundle.trust.crt
smtpd_tls_cert_file = /etc/postfix/crt.pem
smtpd_tls_key_file =  /etc/postfix/key.pem
smtpd_tls_security_level = may
smtpd_use_tls = yes

## We use cyrus for PAM authentication of local users
smtpd_sasl_type = cyrus

## We could use dovecot too.
#smtpd_sasl_type = dovecot
#smtpd_sasl_path = private/auth

smtpd_sasl_auth_enable = yes
smtpd_sasl_authenticated_header = yes
smtpd_recipient_restrictions = permit_mynetworks, permit_sasl_authenticated
##, check_recipient_access, reject_unauth_destination
smtpd_sasl_local_domain = '$CDN'

## Max 25MB mail size
message_size_limit=26214400 

## virus scanner
content_filter=smtp-amavis:[127.0.0.1]:10024

' >> $pc
        fi ## add postfix directives

        echo '# srvctl postfix relaydomains' >> /etc/postfix/relaydomains


set_file /etc/postfix/master.cf '
# Postfix master process configuration file. (minimized) 
# ==========================================================================
# service type  private unpriv  chroot  wakeup  maxproc command + args
#               (yes)   (yes)   (yes)   (never) (100)
# ==========================================================================
smtp      inet  n       -       n       -       -       smtpd
smtps     inet  n       -       n       -       -       smtpd
  -o syslog_name=postfix/smtps
  -o smtpd_tls_wrappermode=yes
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_reject_unlisted_recipient=no
  -o smtpd_recipient_restrictions=permit_sasl_authenticated,reject
pickup    unix  n       -       n       60      1       pickup
cleanup   unix  n       -       n       -       0       cleanup
qmgr      unix  n       -       n       300     1       qmgr
tlsmgr    unix  -       -       n       1000?   1       tlsmgr
rewrite   unix  -       -       n       -       -       trivial-rewrite
bounce    unix  -       -       n       -       0       bounce
defer     unix  -       -       n       -       0       bounce
trace     unix  -       -       n       -       0       bounce
verify    unix  -       -       n       -       1       verify
flush     unix  n       -       n       1000?   0       flush
proxymap  unix  -       -       n       -       -       proxymap
proxywrite unix -       -       n       -       1       proxymap
smtp      unix  -       -       n       -       -       smtp
relay     unix  -       -       n       -       -       smtp
showq     unix  n       -       n       -       -       showq
error     unix  -       -       n       -       -       error
retry     unix  -       -       n       -       -       error
discard   unix  -       -       n       -       -       discard
local     unix  -       n       n       -       -       local
virtual   unix  -       n       n       -       -       virtual
lmtp      unix  -       -       n       -       -       lmtp
anvil     unix  -       -       n       -       1       anvil
scache    unix  -       -       n       -       1       scache

## virus scanner
smtp-amavis unix -    -    n    -    2 smtp
    -o smtp_data_done_timeout=1200
    -o smtp_send_xforward_command=yes
    -o disable_dns_lookups=yes
127.0.0.1:10025 inet n    -    n    -    - smtpd
    -o content_filter=
    -o local_recipient_maps=
    -o relay_recipient_maps=
    -o smtpd_restriction_classes=
    -o smtpd_client_restrictions=
    -o smtpd_helo_restrictions=
    -o smtpd_sender_restrictions=
    -o smtpd_recipient_restrictions=permit_mynetworks,reject
    -o mynetworks=127.0.0.0/8
    -o strict_rfc821_envelopes=yes
    -o smtpd_error_sleep_time=0
    -o smtpd_soft_error_limit=1001
    -o smtpd_hard_error_limit=1000

'

        cat /root/ca-bundle.pem > /etc/postfix/ca-bundle.pem 2> /dev/null
        cat /root/crt.pem > /etc/postfix/crt.pem
        cat /root/key.pem > /etc/postfix/key.pem

        postmap /etc/postfix/relaydomains
        systemctl enable postfix.service
        systemctl start postfix.service

make_aliases_db ''
## this is outdated for fedora 21 and up, ...

if (( $FEDORA < 21 ))
then
    newaliases 
fi

else
    msg "Postfix already installed."
fi ## postfix
## @update-install



