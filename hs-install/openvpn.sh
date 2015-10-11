## configure openvpn
pm install openvpn
pm install easy-rsa

#cp -ai /usr/share/easy-rsa/2.0 ~/srvctl-openvpn-rsa
## TODO continiue here

## add firewall rule
if [ -z "$(firewall-cmd --get-services | grep ' openvpn ')" ]
then
    firewall-cmd --permanent --add-service=openvpn
fi
## reload daemon in firewall.sh

