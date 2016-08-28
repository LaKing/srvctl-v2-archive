## Postfix
## TODO: keep the original postfix conf as a seperate file

if [ ! -f /etc/postfix/main.cf ] || $all_arg_set
then

msg "Installing postfix."

pm postfix

cat $ssl_pem > /etc/postfix/crt.pem
cat $ssl_key > /etc/postfix/key.pem

ssl_cab_hasbang='#'
if [ -f $ssl_cab ]
then
    ssl_cab_hasbang=''
    cat $ssl_cab > /etc/postfix/ca-bundle.pem
fi


chmod 400 /etc/postfix/crt.pem
chmod 400 /etc/postfix/key.pem

set_file /etc/postfix/main.cf '
## srvctl-host postfix configuration file 2.6.x
# Global Postfix configuration file. 

# COMPATIBILITY
compatibility_level = 2

# LOCAL PATHNAME INFORMATION
queue_directory = /var/spool/postfix


command_directory = /usr/sbin
daemon_directory = /usr/libexec/postfix
data_directory = /var/lib/postfix

# QUEUE AND PROCESS OWNERSHIP
mail_owner = postfix

# RECEIVING MAIL
inet_interfaces = all
mynetworks = 127.0.0.0/8 10.0.0.0/8 192.168.0.0/16 [::1]/128 [fe80::]/64

# Enable IPv4, and IPv6 if supported
inet_protocols = all

mydestination = $myhostname, localhost.$mydomain, localhost
unknown_local_recipient_reject_code = 550

alias_maps = hash:/etc/aliases
alias_database = hash:/etc/aliases

# DEBUGGING CONTROL
debug_peer_level = 2

debugger_command = PATH=/bin:/usr/bin:/usr/local/bin; export PATH; (echo cont;echo where) | gdb $daemon_directory/$process_name $process_id 2>&1 > $config_directory/$process_name.$process_id.log & sleep 5

# INSTALL-TIME CONFIGURATION INFORMATION
sendmail_path = /usr/sbin/sendmail.postfix
newaliases_path = /usr/bin/newaliases.postfix
mailq_path = /usr/bin/mailq.postfix
setgid_group = postdrop
html_directory = no
manpage_directory = /usr/share/man
readme_directory = /usr/share/doc/postfix/README_FILES
meta_directory = /etc/postfix
shlib_directory = no
          
## CUSTOM Directives

## use /etc/hosts instead of dns-query
lmtp_host_lookup = native
smtp_host_lookup = native
## in addition, this might be enabled too.
# smtp_dns_support_level = disabled

# TRUST AND RELAY CONTROL
relay_domains = $mydomain, hash:/etc/postfix/relaydomains

## SENDING
## SMTPS
'$ssl_cab_hasbang'smtpd_tls_CAfile =    /etc/postfix/ca-bundle.pem
smtpd_tls_cert_file = /etc/postfix/crt.pem                            
smtpd_tls_key_file =  /etc/postfix/key.pem
smtpd_tls_security_level = may
smtpd_use_tls = yes

## We use cyrus for PAM authentication of local users
smtpd_sasl_type = cyrus

smtpd_sasl_auth_enable = yes
smtpd_sasl_authenticated_header = yes
smtpd_recipient_restrictions = permit_mynetworks, permit_sasl_authenticated
##, check_recipient_access, reject_unauth_destination
smtpd_sasl_local_domain = '$CDN'

## Max 25MB mail size
message_size_limit=26214400 

## virus scanner
content_filter=smtp-amavis:[127.0.0.1]:10024

## opendkim
smtpd_milters           = inet:127.0.0.1:8891
non_smtpd_milters       = $smtpd_milters
milter_default_action   = accept

'

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

add_service postfix

make_aliases_db ''

else
    msg "Postfix already installed."
fi ## postfix
## @update-install




