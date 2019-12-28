FROM alpine:latest

# set version label
ARG BUILD_DATE
ARG VERSION

ARG NZBGET_BRANCH="stable-download"

RUN \
echo "**** Installing Packages ****" && \
apk add --no-cache curl p7zip python3 unrar wget php tor sqlite php-sqlite3 strongswan && \
echo "**** Installing NZBGet ****" && \
mkdir -p /app/nzbget && \
curl -o /tmp/json -L http://nzbget.net/info/nzbget-version-linux.json && NZBGET_VERSION=$(grep "${NZBGET_BRANCH}" /tmp/json  | cut -d '"' -f 4) && \
curl -o /tmp/nzbget.run -L "${NZBGET_VERSION}" && \
sh /tmp/nzbget.run --destdir /app/nzbget && \
echo "**** Configuring NZBGet ****" && \
sed -i \
-e "s#\(MainDir=\).*#\1/data#g" \
-e "s#\(ScriptDir=\).*#\1$\{MainDir\}/scripts#g" \
-e "s#\(WebDir=\).*#\1$\{AppDir\}/webui#g" \
-e "s#\(ConfigTemplate=\).*#\1$\{AppDir\}/webui/nzbget.conf.template#g" \
/defaults/nzbget.conf && \
echo "**** Cleaning up ****" && \
rm -rf /tmp/*

RUN \
echo "**** Enabling SQLite in PHP ****" && \
sed -i 's/\;extension=pdo_sqlite/extension=pdo_sqlite/;s/\;extension=sqlite3/extension=sqlite3/'  /etc/php/php.ini
  
RUN \
echo "**** Setting Tor User and Enabling SocksProxy on Port 9050 ****" && \
echo 'User tor' >> /etc/tor/torrc && \
echo 'SocksPort 0.0.0.0:9050' >> /etc/tor/torrc

RUN \
echo "**** Setting Strongswan ****" && \
printf '%s\n\t' 'conn ipsec_vpn' 'keyexchange=ikev2' 'dpdaction=restart' 'dpddelay=300s' 'eap_identity=USERNAME' 'leftauth=eap-mschapv2' 'left=%defaultroute' 'leftsourceip=%config' 'right=vpn_remote_server' 'rightauth=pubkey' 'rightsubnet=0.0.0.0/0' 'rightid=%any' 'type=tunnel' '#newshosting' 'closeaction=restart' 'keyingtries=%forever' 'auto=start' >  /etc/ipsec.conf && \
sed -i 's/load = yes/load = no/g' /etc/strongswan.d/charon/constraints.conf && \
printf '%s' 'username' ' : EAP ' 'password' >> /etc/ipsec.secrets && \
rmdir /etc/ipsec.d/cacerts && \
ln -s /etc/ssl/certs /etc/ipsec.d/cacerts && \
sed -i 's/load.*$/load = no/' /etc/strongswan.d/charon/resolve.conf

RUN \
echo "**** Setting Cron Job every hour for /scripts/cron.sh ****" && \
echo '1 * * * * /scripts/cron.sh &> /dev/null' >> /var/spool/cron/crontabs/root

RUN \
echo "**** Installing Startup Script ****" && \
curl --connect-timeout 5 --max-time 600 --retry 5 --retry-delay 0 --retry-max-time 60 -o /tmp/scripts-master.zip -L https://github.com/mmtnrw/nzbget-ipsec-tor/archive/master.zip && \
unzip /tmp/scripts-master.zip -d /tmp && \
mv /tmp/nzbget-ipsec-tor-master/start.sh /root && \
rm -rf /tmp/*

# Copying local files
COPY root/ /

# ports and volumes
VOLUME /config /data /media /scripts
EXPOSE 6789 9050 9191

CMD ["/bin/start.sh"]
