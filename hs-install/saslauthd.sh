## saslauthd
msg "Installing saslauthd."

        if [ ! -f /root/saslauthd ]
        then
                msg "No custom saslauthd file detected. Attemt to download a compiled 64bit executable from d250.hu."
                wget -O /root/saslauthd http://d250.hu/scripts/bin/saslauthd
        fi

        if [ ! -f /root/saslauthd ]
        then
                err "Due to incompatibility of saslauthd <= 2.1.26 and perdition, a custom version of saslauthd is required, that has to be located at /root/saslauthd. Exiting."
                exit
        fi

## please refer to dev-notes why this is necessery.

set_file /etc/sasl2/smtpd.conf 'pwcheck_method: saslauthd
mech_list: LOGIN'

        cat $ssl_crt > /etc/perdition/crt.pem
        cat $ssl_key > /etc/perdition/key.pem
        
        chmod 400 /etc/perdition/crt.pem
        chmod 400 /etc/perdition/key.pem

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

        add_service saslauthd

