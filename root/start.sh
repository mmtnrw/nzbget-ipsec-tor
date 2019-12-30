#!/bin/sh

# check if nzbget.conf exists, if not copy default config
if [[ -f /config/nzbget.conf ]]; then

	echo "[info] NZBGet configuration file exists"

else

	echo "[info] NZBGet configuration does not exist, copying default configuration file to /config/..."

	# copy to /config
	cp /defaults/nzbget.conf /config/

	# set maindir to /data folder for downloads
	sed -i 's/MainDir=~\/downloads/MainDir=\/data/g' /config/nzbget.conf

fi

if [[ "${VPN_ENABLED}" == "yes" ]]; then
echo "[info] Starting IPSec....."
echo "[info] IPSec Username=$VPN_USER"
echo "[info] IPSec Password=$VPN_PASS"
echo "[info] IPSec Server=$VPN_SERVER"

sed -i "s/eap_identity=.*$/eap_identity=${VPN_USER}/" /etc/ipsec.conf
sed -i "s/right=.*$/right=${VPN_SERVER}/" /etc/ipsec.conf
echo "${VPN_USER} : EAP ${VPN_PASS}" > /etc/ipsec.secrets

ipsec start
fi


if [[ ! -z "$NAMESERVER" ]]; then
echo "[info] Setting Nameserver to ${NAMESERVER}....."
echo "nameserver ${NAMESERVER}" >> /etc/resolv.conf
else
echo "[info] Setting Nameserver to Cloudflare and Google....."
echo 'nameserver 1.1.1.1' >> /etc/resolv.conf
echo 'nameserver 8.8.8.8' >> /etc/resolv.conf
fi

if [[ "${TOR_ENABLED}" == "yes" ]]; then
echo "[info] Starting Tor....."
sudo -u tor /usr/bin/tor -f /etc/tor/torrc &
fi

echo "[info] Starting Cronie....."
/usr/sbin/crond &

# If a directory exists called web it will be used for PHP Webserver
if [[ -d "/scripts/web" ]]; then 
echo "[info] Starting Serienfilter on Port 9191....."
/usr/bin/php -S 0.0.0.0:9191 -t /scripts/web & 
fi

# start nzbget non-daemonised and specify config file (close stdout due to chatter)
echo "[info] Starting NZBGET Daemon....."
/app/nzbget/nzbget -c /config/nzbget.conf -s 1>&-
