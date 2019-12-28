#!/bin/sh

# check if nzbget.conf exists, if not copy default config
if [[ -f /config/nzbget.conf ]]; then

	echo "[info] NZBGet configuration file exists"

else

	echo "[info] NZBGet configuration does not exist, copying default configuration file to /config/..."

	# copy to /config
	cp /usr/local/bin/nzbget/nzbget.conf /config/

	# set maindir to /data folder for downloads
	sed -i 's/MainDir=~\/downloads/MainDir=\/data/g' /config/nzbget.conf

fi

# Due to the change in install location (AOR to NZBGet installer) we need to patch the NZBGet configuration file
echo "[info] Patching NZBGet config file for WebDir and ConfigTemplate locations..."
sed -i -e 's~WebDir=/usr/share/nzbget/webui~WebDir=${AppDir}/webui~g' /config/nzbget.conf
sed -i -e 's~ConfigTemplate=/usr/share/nzbget/nzbget.conf~ConfigTemplate=${AppDir}/nzbget.conf~g' /config/nzbget.conf

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
echo "nameserver ${NAMESERVER}" > /etc/resolv.conf
else
echo "[info] Setting Nameserver to Cloudflare and Google....."
echo 'nameserver 1.1.1.1' > /etc/resolv.conf
echo 'nameserver 8.8.8.8' >> /etc/resolv.conf
fi



if [[ "${TOR_ENABLED}" == "yes" ]]; then
echo "[info] Starting Tor....."
/usr/bin/tor -f /etc/tor/torrc &
fi

echo "[info] Starting Cronie....."
/usr/bin/crond &

echo "[info] Starting Serienfilter on Port 9191....."
/usr/bin/php -S 0.0.0.0:9191 -t /scripts/web & 

# start nzbget non-daemonised and specify config file (close stdout due to chatter)
echo "[info] Starting NZBGET Daemon....."
/usr/local/bin/nzbget/nzbget --option UnrarCmd=/usr/bin/unrar -c /config/nzbget.conf -s 1>&-
