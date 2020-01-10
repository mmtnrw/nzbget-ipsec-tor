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

echo "[info] Setting up User ID: ${PUID}"
echo "[info] Setting up Group ID: ${PGID}"
echo "[info] **** Warning: Don't forget to chown Files to the User... ***"

if [ ! -z $(getent passwd ${PGID}) ]
then
addgroup --gid "$GID" "mmtnrw"
fi

if [ ! -z $(getent passwd ${PUID}) ]
then
adduser --gecos "" --gid "$GID" -r --uid "$PUID" "mmtnrw"
fi

RUN=s6-setuidgid -u ${PUID} -g ${PGID}
UMASK_SET=${UMASK_SET:-022}
umask "$UMASK_SET"
chown ${PUID}:${GUID} /config/nzbget.conf

echo "[info] Setting up Timezone : $TZ"
ln -snf /usr/share/zoneinfo/$TZ /etc/localtime
echo $TZ > /etc/timezone

if [[ ! -z "$NAMESERVER" ]]; then
echo "[info] Setting Nameserver to ${NAMESERVER}....."
echo "nameserver ${NAMESERVER}" >> /etc/resolv.conf
else
echo "[info] Setting Nameserver to Cloudflare and Google....."
echo 'nameserver 1.1.1.1' >> /etc/resolv.conf
echo 'nameserver 8.8.8.8' >> /etc/resolv.conf
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

echo "[info] Syncing Time...."
ntpd -d -q -n -p time.cloudflare.com &> /dev/null

if [[ "${TOR_ENABLED}" == "yes" ]]; then
echo "[info] Starting Tor....."
s6-setuidgid -u tor -g tor /usr/bin/tor -f /etc/tor/torrc &
fi

echo "[info] Starting Cronie....."
echo "**** Setting Cron Job every hour for /scripts/cron.sh ****" && \
echo '1 * * * * /scripts/cron.sh &> /dev/null' >> "/var/spool/cron/crontabs/`getent passwd "$PUID" | cut -d: -f1`"

/usr/sbin/crond &

# If a directory exists called web it will be used for PHP Webserver
if [[ -d "/scripts/web" ]]; then 
echo "[info] Starting Serienfilter on Port 9191....."
$RUN /usr/bin/php -S 0.0.0.0:9191 -t /scripts/web & 
fi

# start nzbget non-daemonised and specify config file (close stdout due to chatter)
echo "[info] Starting NZBGET Daemon....."
$RUN /app/nzbget/nzbget -c /config/nzbget.conf -s 1>&-
