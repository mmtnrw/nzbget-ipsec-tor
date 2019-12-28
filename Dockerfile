FROM archlinux/base:latest

#Update Pacman
RUN pacman -Sy

#Install needed Programs
RUN pacman -S --needed libxml2 p7zip python par2cmdline php cronie nano php-sqlite tor strongswan nzbget unrar procps-ng wget unzip --noconfirm

#Cleanup Pacman
RUN pacman -Scc --noconfirm

#Enable php.ini SQLITE
RUN sed -i 's/\;extension=pdo_sqlite/extension=pdo_sqlite/;s/\;extension=sqlite3/extension=sqlite3/'  /etc/php/php.ini
  
#Set Tor User for Daemon Mode
RUN echo 'User tor' >> /etc/tor/torrc
RUN echo 'SocksPort 0.0.0.0:9050' >> /etc/tor/torrc

# Configuring IPSEC

RUN printf '%s\n\t' 'conn ipsec_vpn' 'keyexchange=ike' 'dpdaction=restart' 'dpddelay=300s' 'eap_identity=USERNAME' 'leftauth=eap-mschapv2' 'left=%defaultroute' 'leftsourceip=%config' 'right=MY_VPN_SERVER' 'rightauth=pubkey' 'rightsubnet=0.0.0.0/0' 'rightid=%any' 'type=tunnel' '#newshosting' 'closeaction=restart' 'keyingtries=%forever' 'auto=start' >  /etc/ipsec.conf
RUN sed -i 's/load = yes/load = no/g' /etc/strongswan.d/charon/constraints.conf
RUN printf '%s' 'username' ' : EAP ' 'password' >> /etc/ipsec.secrets
RUN rmdir /etc/ipsec.d/cacerts
RUN ln -s /etc/ssl/certs /etc/ipsec.d/cacerts

RUN sed -i 's/load.*$/load = no/' /etc/strongswan.d/charon/resolve.conf

# Configuring Crontab
RUN echo '1 * * * * /scripts/cron.sh &> /dev/null' | tee -a /var/spool/cron/root

# Loading Startup Script
RUN curl --connect-timeout 5 --max-time 600 --retry 5 --retry-delay 0 --retry-max-time 60 -o /tmp/scripts-master.zip -L https://github.com/mmtnrw/nzbget-ipsec-tor/archive/master.zip

# unzip scripts
RUN unzip /tmp/scripts-master.zip -d /tmp
RUN mv /tmp/nzbget-ipsec-tor-master/start.sh /root

# map /config to host defined config path (used to store configuration from app)
VOLUME /config

# map /data to host defined data path (used to store downloads or use blackhole)
VOLUME /data

# map /media to host defined media path (used to read/write to media library)
VOLUME /media

VOLUME /scripts

# expose port for http
EXPOSE 6789

#expose port for serienfilter
EXPOSE 9191

#expose port for tor socksproxy
EXPOSE 9050

CMD ["/root/startup.sh" "CONSOLE"]
