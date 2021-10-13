FROM alpine:latest

# set version label
ARG BUILD_DATE
ARG VERSION

ARG NZBGET_BRANCH="testing-download"

RUN \
echo "**** Installing Packages ****" && \
apk add --no-cache curl p7zip python3 unrar wget php tor sqlite php-sqlite3 strongswan php-pdo_sqlite nano sudo php-curl php-json openssl tzdata s6 php7-dom python3 py3-pip && \
echo "**** Installing NZBGet ****" && \
mkdir -p /app/nzbget && \
curl -o /tmp/json -L http://nzbget.net/info/nzbget-version-linux.json && NZBGET_VERSION=$(grep "${NZBGET_BRANCH}" /tmp/json  | cut -d '"' -f 4) && \
curl -o /tmp/nzbget.run -L "${NZBGET_VERSION}" && \
sh /tmp/nzbget.run --destdir /app/nzbget && \
echo "**** Configuring NZBGet ****" && \
mkdir -p /defaults && \
cp /app/nzbget/nzbget.conf /defaults/nzbget.conf && \
sed -i \
-e "s#\(MainDir=\).*#\1/data#g" \
-e "s#\(ScriptDir=\).*#\1$\{MainDir\}/scripts#g" \
-e "s#\(WebDir=\).*#\1$\{AppDir\}/webui#g" \
-e "s#\(ConfigTemplate=\).*#\1$\{AppDir\}/webui/nzbget.conf.template#g" \
/defaults/nzbget.conf && \
echo "**** Cleaning up ****" && \
rm -rf /tmp/*

RUN pip3 install requests requests[socks] jsonrpclib feedparser pathlib datetime

RUN \
echo "**** Setting Tor User and Enabling SocksProxy on Port 9050 ****" && \
echo 'SocksPort 0.0.0.0:9050' > /etc/tor/torrc && \
echo 'User tor' >> /etc/tor/torrc && \
echo 'DataDirectory /tmp/tor' >> /etc/tor/torrc

RUN \
echo "**** Setting Strongswan ****" && \
printf '%s\n\t' 'conn ipsec_vpn' 'keyexchange=ike' 'dpdaction=restart' 'dpddelay=300s' 'eap_identity=USERNAME' 'leftauth=eap-mschapv2' 'left=%defaultroute' 'leftsourceip=%config' 'right=vpn_remote_server' 'rightauth=pubkey' 'rightsubnet=0.0.0.0/0' 'rightid=%any' 'type=tunnel' '#newshosting' 'closeaction=restart' 'keyingtries=%forever' 'auto=start' >  /etc/ipsec.conf && \
sed -i 's/load = yes/load = no/g' /etc/strongswan.d/charon/constraints.conf && \
printf '%s' 'username' ' : EAP ' 'password' >> /etc/ipsec.secrets && \
rmdir /etc/ipsec.d/cacerts && \
ln -s /etc/ssl/certs /etc/ipsec.d/cacerts && \
sed -i 's/load.*$/load = no/' /etc/strongswan.d/charon/resolve.conf

# Copying local files
COPY root/ /root/

RUN \
chmod +x /root/start.sh && \
chmod +x /root/vpn.sh && \
chmod +x /root/update.sh

# ports and volumes
VOLUME /config /data /media /scripts
EXPOSE 6789 9050 9191

CMD ["/root/start.sh"]
