#!/bin/bash

hint "diagnose" "Run a set of diagnostic commands."
if [ "$CMD" == "diagnose" ]
then	
	msg "VIRUS CHECK"
	freshclam 
	mkdir -p /root/srvctl-karantene
	clamscan -r --move=/root/srvctl-karantene /home
	clamscan -r --move=/root/srvctl-karantene /srv

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

	msg "CONNECTED SHELL USERS"
	w
ok
fi

