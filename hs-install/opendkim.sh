## IMAP4S proxy
if [ ! -f /etc/opendkim.conf ] || $all_arg_set
then
        bak /etc/opendkim.conf

        log "Install opendkim, to sign e-mail's."

        pm opendkim

        set_file /etc/opendkim.conf '#### srvctl tuned onemdkim.conf
        
## CONFIGURATION OPTIONS
PidFile        /var/run/opendkim/opendkim.pid

##  Selects operating modes. Valid modes are s (sign) and v (verify). Default is v.
Mode        v


Syslog        yes
SyslogSuccess        yes
LogWhy        yes
UserID        opendkim:opendkim
Socket        inet:8891@localhost
Umask        002

SendReports        yes
# ReportAddress        "Example.com Postmaster" <postmaster@example.com>

SoftwareHeader        yes

## SIGNING OPTIONS
Canonicalization        relaxed/relaxed

Selector        default
MinimumKeyBits        1024

KeyTable        /var/srvctl-host/opendkim/KeyTable
SigningTable        refile:/var/srvctl-host/opendkim/SigningTable
ExternalIgnoreList        refile:/var/srvctl-host/opendkim/TrustedHosts
InternalHosts        refile:/var/srvctl-host/opendkim/TrustedHosts


'
        regenerate_opendkim 

        systemctl stop opendkim.service
        systemctl enable opendkim.service
        systemctl start opendkim.service
        systemctl status opendkim.service
        
        
else
    msg "opendkim is already installed."
fi ## install opendkim

