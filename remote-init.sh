#!/bin/sh

s_time=`date +%s`
IP=$1
EMAIL=$2
DDNS=$3
DDNSPASS=$4
PIPASS=$5
PEERS=$6
COPYFROMDDNS=$7

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

echo "--- A-HOLE running local init"
ssh -oStrictHostKeyChecking=no ubuntu@${IP} ./local-init.sh

if [ -z "$COPYFROMDDNS" ]; then
    echo "--- A-HOLE no DDNS specified to restore from; continuing"
else
    echo "--- A-HOLE restoring metadata from ${COPYFROMDDNS}"
    mkdir -p ./tmp
    scp -r ubuntu@${COPYFROMDDNS}:~/pihole-etc-dnsmasq.d ./tmp/
    scp -r ./tmp/pihole-etc-dnsmasq.d ubuntu@${IP}:~/
    scp -r ubuntu@${COPYFROMDDNS}:~/pihole-etc-pihole ./tmp/
    scp -r ./tmp/pihole-etc-pihole ubuntu@${IP}:~/
    scp -r ubuntu@${COPYFROMDDNS}:~/wireguard-config ./tmp/
    scp -r ./tmp/wireguard-config ubuntu@${IP}:~/
    rm -rf ./tmp
fi

# bring up the platform
echo "--- A-HOLE bringing up platform"
ssh -oStrictHostKeyChecking=no ubuntu@${IP} ./control.py - up

e_time=`date +%s`
runtime=$((e_time-s_time))

echo "--- A-HOLE took ${runtime}s to init. now sleeping for 120s to allow reboot and DDNS to propagate"
ssh -oStrictHostKeyChecking=no ubuntu@${IP} sudo reboot

sleep 120
ssh ubuntu@${IP}