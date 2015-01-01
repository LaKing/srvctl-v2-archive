#!/bin/bash

hint "sec-dns" "Set up as a secondary DNS server"
if [ "$CMD" == "sec-dns" ]
then	

	systemctl stop named.service

	rm -rf /root/dns
	rm -rf /var/named/srvctl

	mkdir -p /root/dns
	cd /root/dns
	wget https://$CDN/dns.tar.gz
	tar -xf dns.tar.gz
	rm -rf /root/dns/dns.tar.gz


	mkdir -p /etc/srvctl
	mkdir -p /var/named/srvctl
	chown -R named:named /var/named/srvctl

	rsync -a /root/dns/etc/srvctl/named.slave.conf.global.r2.d250.hu /etc/srvctl
	rsync -a /root/dns/var/named/srvctl /var/named

	rm -rf /var/named/srvctl/*.zone

	systemctl start named.service
	systemctl status named.service

fi
