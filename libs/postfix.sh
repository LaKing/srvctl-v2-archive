function write_ve_postfix_main {

_c=$1
to=/dev/null
isMX=false
hasMX=false

if $onHS
then
    to=$SRV/$_c/rootfs/etc/postfix/main.cf
fi

if $onVE
then
    to=/etc/postfix/main.cf 
fi

if [ "${_c:0:5}" == "mail." ]
then
    isMX=true
    hasMX=true
fi

if [ -d $SRV/mail.$_c/rootfs ]
then
    hasMX=true
fi

echo '
## srvctl-generated postfix main.cf '$install_ver'

# COMPATIBILITY
compatibility_level = 2

# LOCAL PATHNAME INFORMATION
queue_directory = /var/spool/postfix
command_directory = /usr/sbin
daemon_directory = /usr/libexec/postfix
data_directory = /var/lib/postfix

# QUEUE AND PROCESS OWNERSHIP
mail_owner = postfix

# The default_privs parameter specifies the default rights used by
# the local delivery agent for delivery to external file or command.
# These rights are used in the absence of a recipient user context.
# DO NOT SPECIFY A PRIVILEGED USER OR THE POSTFIX OWNER.
#
#default_privs = nobody

# INTERNET HOST AND DOMAIN NAMES
#myhostname = host.domain.tld
#mydomain = domain.tld

# SENDING MAIL
#myorigin = $myhostname
#myorigin = $mydomain


# RECEIVING MAIL

inet_interfaces = all
inet_protocols = all

# REJECTING MAIL FOR UNKNOWN LOCAL USERS
unknown_local_recipient_reject_code = 550

# TRUST AND RELAY CONTROL
##### TODO needfix ### relay_domains = $mydestination

# INTERNET OR INTRANET
## relayhost = 10.10.0.1

# REJECTING UNKNOWN RELAY USERS
#relay_recipient_maps = hash:/etc/postfix/relay_recipients

# ALIAS DATABASE
alias_maps = hash:/etc/aliases
alias_database = hash:/etc/aliases

# DELIVERY TO MAILBOX
home_mailbox = Maildir/

# DEBUGGING CONTROL
debug_peer_level = 2

debugger_command =
         PATH=/bin:/usr/bin:/usr/local/bin:/usr/X11R6/bin
         ddd $daemon_directory/$process_name $process_id & sleep 5

# INSTALL-TIME CONFIGURATION INFORMATION
sendmail_path = /usr/sbin/sendmail.postfix
newaliases_path = /usr/bin/newaliases.postfix
mailq_path = /usr/bin/mailq.postfix
setgid_group = postdrop
html_directory = no
manpage_directory = /usr/share/man
sample_directory = /usr/share/doc/postfix/samples
readme_directory = /usr/share/doc/postfix/README_FILES
meta_directory = /etc/postfix
shlib_directory = /usr/lib64/postfix


## If required Catch all mail defined in ..
# virtual_alias_maps = hash:/etc/postfix/catchall

## Max 25MB mail size
message_size_limit=26214400

' > $to

if $hasMX
then

    if $isMX
    then
## this is mail.
echo '
## we need to change myhostname
myorigin = '${_c:5}'
        
## set localhost.localdomain in mydestination to enable local mail delivery
mydestination = $myhostname, '${_c:5}', localhost, localhost.localdomain
' >> $to

    else
## this is not the mail

echo '
## set localhost.localdomain in mydestination to enable local mail delivery
mydestination = localhost, localhost.localdomain
' >> $to
        
    fi

else

## no seperate mail.
echo '
## set localhost.localdomain in mydestination to enable local mail delivery
mydestination = $myhostname, mail.$myhostname, localhost, localhost.localdomain
' >> $to

fi
echo restart postfix $_c 
ssh $_c 'systemctl restart postfix.service'
}

