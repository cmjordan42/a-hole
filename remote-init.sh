#!/bin/sh

s_time=`date +%s`
IP=$1
EMAIL=$2
DDNS=$3
DDNSPASS=$4
PIPASS=$5
PEERS=$6

if [ -z "$IP" ] || [ -z "$EMAIL" ] || [ -z "$DDNS" ] || [ -z "$DDNSPASS" ] || [ -z "$PIPASS" ] || [ -z "$PEERS" ]; then
    echo "missing parameters: remote-init.sh <IP> <email address> <DDNS> <DDNS password> <password to set for Pihole> <list of Wireguard peer names>"
    exit
fi

echo "--- A-HOLE stage files to ./${DDNS} and substitute configuration parameters"
mkdir -p ./${DDNS}
cp ./template/* ./${DDNS}/
sed -i "s/DDNS\!\!\!/$DDNS/g" ./${DDNS}/*
sed -i "s/EMAIL\!\!\!/$EMAIL/g" ./${DDNS}/*
sed -i "s/DDNSPASS\!\!\!/$DDNSPASS/g" ./${DDNS}/*
sed -i "s/PIPASS\!\!\!/$PIPASS/g" ./${DDNS}/*
sed -i "s/PEERS\!\!\!/$PEERS/g" ./${DDNS}/*

echo "--- A-HOLE copying files to target host"
scp -oStrictHostKeyChecking=no -r ./${DDNS}/* ubuntu@${IP}:~/

echo "--- A-HOLE basic updates for the host machine"
ssh -oStrictHostKeyChecking=no ubuntu@${IP} sudo DEBIAN_FRONTEND=noninteractive apt --yes --allow-change-held-packages update
ssh -oStrictHostKeyChecking=no ubuntu@${IP} sudo DEBIAN_FRONTEND=noninteractive apt --yes --allow-change-held-packages upgrade
ssh -oStrictHostKeyChecking=no ubuntu@${IP} sudo DEBIAN_FRONTEND=noninteractive apt --yes --allow-change-held-packages autoremove
ssh -oStrictHostKeyChecking=no ubuntu@${IP} sudo DEBIAN_FRONTEND=noninteractive apt --yes --allow-change-held-packages autoclean

echo "--- A-HOLE install dependent packages"
ssh -oStrictHostKeyChecking=no ubuntu@${IP} sudo DEBIAN_FRONTEND=noninteractive apt install --yes --allow-change-held-packages python3 docker.io docker-compose

echo "--- A-HOLE configure host machine for unattended upgrades"
ssh -oStrictHostKeyChecking=no ubuntu@${IP} sudo DEBIAN_FRONTEND=noninteractive apt install --yes --allow-change-held-packages unattended-upgrades apt-listchanges bsd-mailx
ssh -oStrictHostKeyChecking=no ubuntu@${IP} sudo dpkg-reconfigure -fnoninteractive -plow unattended-upgrades

echo "--- A-HOLE add user to docker group to avoid sudo"
ssh -oStrictHostKeyChecking=no ubuntu@${IP} sudo usermod -aG docker ubuntu

echo "--- A-HOLE configure docker to start on machine reboot"
ssh -oStrictHostKeyChecking=no ubuntu@${IP} sudo systemctl enable docker.service
ssh -oStrictHostKeyChecking=no ubuntu@${IP} sudo systemctl enable containerd.service

echo "--- A-HOLE schedule host machine to reboot once a week on Wednesday morning"
ssh -oStrictHostKeyChecking=no ubuntu@${IP} sudo crontab -l | grep -q 'shutdown -r' && echo 'a scheduled reboot entry exists' || (crontab -l 2>/dev/null; echo "0 7 * * 3 /sbin/shutdown -r") | crontab -

# bring up the platform
echo "--- A-HOLE bringing up platform"
ssh -oStrictHostKeyChecking=no ubuntu@${IP} ./control.py - up

e_time=`date +%s`
runtime=$((e_time-s_time))

echo "--- A-HOLE took ${runtime}s to init. now sleeping for 120s to allow reboot and DDNS to propagate"
ssh -oStrictHostKeyChecking=no ubuntu@${IP} sudo reboot

sleep 120
ssh ubuntu@${IP}
