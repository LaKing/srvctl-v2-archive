## saslauthd

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

