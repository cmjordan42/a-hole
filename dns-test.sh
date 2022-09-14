#!/bin/bash

METHOD=$1
SERVER=$2

compare()
{
    NAME="$1"
    TEST="$2"
    COMP="$3"
    echo "--- ${NAME}"
    #echo "TEST $TEST"
    #echo "COMP $COMP"
    diff "$TEST" "$COMP"
}

if [ -z "$SERVER" ]; then echo "test server needs to be specified"; exit; fi

valid=""
methods="dns dot doh dnscrypt quic"
for m in $methods; do
    if [ "$m" == "$METHOD" ]; then
        valid="valid"
    fi
done
if [ -z "$valid" ]; then exit; fi

if [ -z "$METHOD" ]; then echo "method needs to be specified"; exit;
elif [ "$METHOD" == "dns" ]; then
    echo "---- DNS"
    diff <(dig @${SERVER} example.com) <(dig @dns.google example.com)
elif [ "$METHOD" == "dot" ]; then
    echo "---- DoT"
    diff <(kdig -d @${SERVER} +tls-ca +tls-host=${SERVER} example.com.) <(kdig -d @dns.google +tls-ca +tls-host=dns.google example.com.)
elif [ "$METHOD" == "doh" ]; then
    echo "---- DoH-1"
    diff <(curl --doh-url https://${SERVER}/dns-query example.com) <(curl --doh-url https://dns.google/dns-query example.com)

    echo "---- DoH-2"
    diff <(curl -H 'accept: application/dns-message' 'https://'${SERVER}'/dns-query?dns=q80BAAABAAAAAAAAA3d3dwdleGFtcGxlA2NvbQAAAQAB') <(curl -H 'accept: application/dns-message' 'https://dns.google/dns-query?dns=q80BAAABAAAAAAAAA3d3dwdleGFtcGxlA2NvbQAAAQAB')

    echo "---- DoH-3"
    diff <(kdig @${server} +https +https-get example.com.) <(kdig @dns.google +https +https-get example.com.)
elif [ "$METHOD" == "dnscrypt" ]; then
    echo "a bit more complicated"
elif [ "$METHOD" == "quic" ]; then
    echo "a bit more complicated"
fi