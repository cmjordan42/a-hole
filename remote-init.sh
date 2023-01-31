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

ssh-keygen -f "~/.ssh/known_hosts" -R "${DDNS}"

echo "--- A-HOLE waiting for availability of ${IP}"
continue="yes"
while [ "$continue" = "yes" ]; do
    ssh ubuntu@${IP} uptime
    rc=$?

    if [ $rc -ne 255 ] ; then
        echo "--- A-HOLE ${IP} is available; proceeding"
        continue="no"
    else
        echo "--- A-HOLE ${IP} unavailable"
        sleep 3
    fi
done

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
ssh -oStrictHostKeyChecking=no ubuntu@${IP} ./init-ahole.sh

if [ -z "$COPYFROMDDNS" ]; then
    echo "--- A-HOLE no DDNS specified to restore from; continuing"
else
    mkdir -p ./tmp

    echo "--- A-HOLE restoring metadata from ${COPYFROMDDNS}:~/pihole-etc-dnsmasq.d"
    scp -oStrictHostKeyChecking=no -r ubuntu@${COPYFROMDDNS}:~/pihole-etc-dnsmasq.d ./tmp/
    echo "--- A-HOLE restoring metadata to ${IP}:~/pihole-etc-dnsmasq.d"
    scp -oStrictHostKeyChecking=no -r ./tmp/pihole-etc-dnsmasq.d ubuntu@${IP}:~/

    echo "--- A-HOLE restoring metadata from ${COPYFROMDDNS}:~/pihole-etc-pihole"
    scp -oStrictHostKeyChecking=no -r ubuntu@${COPYFROMDDNS}:~/pihole-etc-pihole ./tmp/
    echo "--- A-HOLE restoring metadata to ${IP}:~/pihole-etc-pihole"
    scp -oStrictHostKeyChecking=no -r ./tmp/pihole-etc-pihole ubuntu@${IP}:~/
    
    echo "--- A-HOLE restoring metadata from ${COPYFROMDDNS}:~/wireguard-config"
    scp -oStrictHostKeyChecking=no -r ubuntu@${COPYFROMDDNS}:~/wireguard-config ./tmp/
    echo "--- A-HOLE restoring metadata to ${IP}:~/wireguard-config"
    scp -oStrictHostKeyChecking=no -r ./tmp/wireguard-config ubuntu@${IP}:~/

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