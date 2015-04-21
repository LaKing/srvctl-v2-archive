#!/bin/bash

hint "diagnose" "Run a set of diagnostic commands."
if [ "$CMD" == "diagnose" ]
then        
        msg "VIRUS CHECK"
        karantene_path="$(realpath ~)"
        mkdir -p $karantene_path
        
        if $isUSER
        then
            clamscan -r --move=$karantene_path ~
        else
            freshclam 
            clamscan -r --move=$karantene_path /home
            clamscan -r --move=$karantene_path /srv
            clamscan -r --move=$karantene_path /var/www
        fi
        #echo "Postfix: "$(systemctl is-active postfix.service)        
        #echo "Dovecot: "$(systemctl is-active dovecot.service)

        msg "FULL STATUS MESSAGES"
        systemctl status pop3s.service
        systemctl status imap4s.service
        systemctl status imap4.service
        systemctl status saslauthd.service
        systemctl status postfix.service
        systemctl status pound.service
        systemctl status fail2ban.service
        fail2ban-client status

        msg "NETWORK PORTS and PROTOCOLLS"
        netstat -tulpn
        
        if $isROOT
        then
            msg "POP3"
            netstat -np | grep ":995"
            msg "IMAP4S"
            netstat -np | grep ":993"
            msg "IMAP for SMTPS auth"
            netstat -np | grep ":143"
            msg "SMTPS"
            netstat -np | grep ":465"
            msg "SMTP"
            netstat -np | grep ":25"
            msg "SSH"
            netstat -np | grep ":22"
            msg "FTP"
            netstat -np | grep ":21"
            msg "HTTP"
            netstat -np | grep ":80"
            netstat -np | grep ":443"
        fi
        
        msg "CONNECTED SHELL USERS"
        w
        
ok
fi
man '
    Set of troubleshooting commands. 
    Scan for viruses first, then display status messages, and list important network port statuses.
'
