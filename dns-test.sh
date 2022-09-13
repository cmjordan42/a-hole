#!/bin/bash

sudo apt install -y knot-dnsutils

METHOD=$1
SERVER=$2

compare()
{
    NAME="$1"
    TEST="$2"
    COMP="$3"
    echo $NAME
    echo "TEST $TEST"
    echo "COMP $COMP"
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
    1=1
elif [ "$METHOD" == "dot" ]; then
    test=`kdig -d @${SERVER} +tls-ca +tls-host=${SERVER} example.com.`
    comp=`kdig -d @8.8.8.8 +tls-ca +tls-host=dns.google.com example.com.`
    compare "\ndot1\n" "$test" "$comp"
elif [ "$METHOD" == "doh" ]; then
    test=`kdig @${server} +https example.com.`
    comp=`kdig @1.1.1.1 +https example.com.`
    compare "\ndoh1\n" "$test" "$comp"

    test=`kdig @${server} +https=/doh example.com.`
    comp=`kdig @1.1.1.1 +https=/doh example.com.`
    compare "\ndoh2\n" "$test" "$comp"

    test=`kdig @${server} +https +https-get example.com.`
    comp=`kdig @1.1.1.1 +https +https-get example.com.`
    compare "\ndoh3\n" "$test" "$comp"
elif [ "$METHOD" == "dnscrypt" ]; then
    1=1
elif [ "$METHOD" == "quic" ]; then
    1=1
fi