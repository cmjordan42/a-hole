#!/bin/sh

s_time=$(date +%s)
IP=$1
EMAIL=$2
DDNS=$3
DDNSPASS=$4
PIPASS=$5
PEERS=$6
COPYFROMIP=$7

if [ -z "$IP" ] || [ -z "$EMAIL" ] || [ -z "$DDNS" ] || [ -z "$DDNSPASS" ] || [ -z "$PIPASS" ] || [ -z "$PEERS" ]; then
    echo "missing parameters: remote-init.sh <IP> <email address> <DDNS> <DDNS password> <password to set for Pihole> <list of Wireguard peer names>"
    exit
fi

ssh-keygen -f "${HOME}/.ssh/known_hosts" -R "${DDNS}"

echo "--- A-HOLE waiting for availability of ${IP}"
continue="yes"
while [ "$continue" = "yes" ]; do
    ssh -oStrictHostKeyChecking=no ubuntu@"${IP}" uptime
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
dir="./${DDNS}/"
mkdir -p "$dir"
cp ./template/* "$dir"
sed -i "s/DDNS\!\!\!/$DDNS/g" "$dir"*
sed -i "s/EMAIL\!\!\!/$EMAIL/g" "$dir"/*
sed -i "s/DDNSPASS\!\!\!/$DDNSPASS/g" "$dir"/*
sed -i "s/PIPASS\!\!\!/$PIPASS/g" "$dir"/*
sed -i "s/PEERS\!\!\!/$PEERS/g" "$dir"/*

echo "--- A-HOLE copying files to target host"
rsync -r --progress "$dir"* ubuntu@"${IP}":~/a-hole/

echo "--- A-HOLE running local init"
ssh -oStrictHostKeyChecking=no ubuntu@"${IP}" ./a-hole/init-ahole.sh

if [ -z "$COPYFROMIP" ]; then
    echo "--- A-HOLE no DDNS specified to restore from; continuing"
else
    mkdir -p ./tmp

    echo "--- A-HOLE restoring metadata from ${COPYFROMIP}:~/a-hole/pihole-etc-dnsmasq.d"
    scp -oStrictHostKeyChecking=no -r ubuntu@"${COPYFROMIP}":~/pihole-etc-dnsmasq.d ./tmp/

    echo "--- A-HOLE restoring metadata from ${COPYFROMIP}:~/a-hole/pihole-etc-pihole"
    scp -oStrictHostKeyChecking=no -r ubuntu@"${COPYFROMIP}":~/pihole-etc-pihole ./tmp/
    
    echo "--- A-HOLE restoring metadata from ${COPYFROMIP}:~/a-hole/wireguard-config"
    scp -oStrictHostKeyChecking=no -r ubuntu@"${COPYFROMIP}":~/wireguard-config ./tmp/

    echo "--- A-HOLE restoring metadata to ${IP}:~/a-hole/"
    scp -oStrictHostKeyChecking=no -r ./tmp/ ubuntu@"${IP}":~/a-hole/

    rm -rf ./tmp
fi

# bring up the platform
echo "--- A-HOLE bringing up platform"
ssh -oStrictHostKeyChecking=no ubuntu@"${IP}" ./a-hole/control.py - up

e_time=$(date +%s)
runtime=$((e_time-s_time))

echo "--- A-HOLE took ${runtime}s to init. now sleeping for 120s to allow reboot and DDNS to propagate"
ssh -oStrictHostKeyChecking=no ubuntu@"${IP}" sudo reboot

sleep 120
ssh ubuntu@"${IP}"