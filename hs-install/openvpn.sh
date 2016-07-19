msg "Installing openvpn"

## configure openvpn
pm openvpn

mkdir -p /etc/srvctl/openvpn

if [ ! -f /etc/openvpn/dh2048.pem ]
then
    openssl dhparam -out /etc/openvpn/dh2048.pem 2048
fi 

regenerate_hosts_config




