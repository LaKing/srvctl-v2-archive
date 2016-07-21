## IMAP4S proxy
if [ ! -f /etc/opendkim.conf ] || $all_arg_set
then

        msg "Install opendkim, to sign e-mail's."

        pm opendkim

        save_file /etc/opendkim.conf '#### srvctl tuned onemdkim.conf
        
## CONFIGURATION OPTIONS
PidFile        /var/run/opendkim/opendkim.pid

##  Selects operating modes. Valid modes are s (sign) and v (verify). Default is v.
Mode        vs


Syslog        yes
SyslogSuccess        yes
LogWhy        yes
UserID        opendkim:opendkim
Socket        inet:8891@127.0.0.1
Umask        002

SendReports        yes
# ReportAddress        "Example.com Postmaster" <postmaster@example.com>

SoftwareHeader        yes

## SIGNING OPTIONS
Canonicalization        relaxed/relaxed

Selector        default
MinimumKeyBits        1024

KeyTable        /var/opendkim/KeyTable
SigningTable        refile:/var/opendkim/SigningTable
ExternalIgnoreList        refile:/var/opendkim/TrustedHosts
InternalHosts        refile:/var/opendkim/TrustedHosts


'
        regenerate_opendkim 

        add_service opendkim
        
        
else
    msg "opendkim is already installed."
fi ## install opendkim

