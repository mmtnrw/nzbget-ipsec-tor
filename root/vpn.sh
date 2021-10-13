#!/bin/sh
BASEDIR=$(dirname "$0")

if [[ "${VPN_TYPE}" == "NordVPN" ]]; then
echo "[info] Using NordVPN....."
VPN_SERVER=`curl --silent 'https://nordvpn.com/wp-admin/admin-ajax.php?action=servers_recommendations'|sed -n 's/.*"hostname":"\([^"]*\)"/\1/p'|cut -f1 -d",")`
sed -i "s/right=.*$/right=${VPN_SERVER}/" /etc/ipsec.conf
ipsec restart
fi
