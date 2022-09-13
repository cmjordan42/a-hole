# `a-hole`
(tldr at the end)

A blackhole for ads, or an ad-hole.

But since it provides inbound interfaces that are secure and semi-hidden from ISPs and other onlookers, it's `a*hole`.

Sorry about the name.

# Why!?
As a pet project in 2019, I built all of this incrementally and a lot less cleanly, but it worked like a charm for me and mine. In Summer 2022, the public cloud VM in which I had built all of this - with limited version control - imploded. Virtually all was lost and the DNS on my devices was relegated to service from the likes of Comcast and spectated by the Chinese Communist Party.

So, I decided to do it again but do it in a way that's entirely reproduceable so when the next VM implodes, it would be a matter of minutes until I had everything up and running again on a new host.

# Objectives
The goal of this is to provide a low-maintenance setup to provide secure ad-blocking DNS service with a spectrum of access methods for a handful of known users and their devices.

Downtime is acceptable and in order to keep the installation within the bounds of the Oracle Cloud free tier, there is limited fault tolerance and redundancy. Expect an installation to have issues semi-annually that can be resolved with minimal debugging or maybe just a reinstallation or an update. Public access to DoT and DoH is not an issue, so long as it's limited and without apparent malice.

# Overview of components
## [Ubuntu](https://ubuntu.com/)
Ubuntu on an AMD processor is the OS of choice where I'm certain this works. Ubuntu because it's universal; AMD because it's one of the two flavors of free-tier hardware in Oracle Cloud's free tier.

## [Docker](https://www.docker.com/)
Docker was a key ingredient to this to keep portability high and not recreate infrastructure that already existed, but also rely on configuration over code to allow relatively low-tech people to have a chance to get this up and running for themselves and perhaps become slightly-higher-tech through the process.

## [Pihole](https://pi-hole.net/)
Pihole is at the center of this. The primary value comes from having Pihole provide ad blocking and other custom domain blocking.

## [Wireguard](https://www.wireguard.com/)
Wireguard provides tunneling and VPN functionality to allow a client device anywhere in the world to have access to all of the resources and functionality in `a-hole`.

## [DNSProxy](https://github.com/AdguardTeam/dnsproxy/)
DNSProxy provides DoT and DoH processor endpoints to handle SSL and then farm it off to the internal DNS filtering and processing stack. I wish that dnsproxy published it's own certified docker container, but beggars can't be choosers.

## [Unbound](https://www.nlnetlabs.nl/projects/unbound/about/)
Unbound fits in as a local upstream DNS server which adds a bit of security and privacy before resolving DNS with the broader Internet. I wish that unbound published it's own certified docker container, but beggars can't be choosers.

## [Certbot](https://certbot.eff.org/)
Certbot provides lifecycle management for creating and maintaining security certificates to facilitate TLS and HTTPS, specifically in DNS-over-TLS.

## [No-IP](https://www.noip.com/)
NO-IP is a DDNS provider that has been around for decades and I chose them simply because I have had a DDNS registered with them for decades. Conveniently, there was also a light-weight docker container out there that can automatically update a DDNS entry. I wish that No-IP published it's own certified docker container, but beggars can't be choosers.

## Support scripts
There are also some scripts which streamline setup (`remote-init.sh`), which streamline control of an active installation (`control.py`), and which aid in debugging various DNS functions (`dns-test.sh`).

# tldr;
Ad-blocking DNS-over-TLS, DNS-over-HTTPS, and DNS-via-VPN. Instructions to get it running are below.

>Prep time: 11 min\
>Baking time: 4 min

# How-to
## 1. Get cloud infrastructure
You'll need a cloud infrastructure provider where you can:
- Instantiate a host instance
- Configure the firewall rules to allow ports to pass through from the Internet into the instance

For example, Oracle Cloud as it has an "Always Free" tier that allows me to run this for free. Follow the steps below to get through this.

1. 

## 2. Set up firewall rules
We've got all of the firewall management within the host handled, but we'll need to make sure that our cloud infrastructure provider allows a few ports through to our host. They are: 
- `SSH` (TCP #22)
- `Wireguard` (UDP #51820)
- `DNS-over-TLS` via `dnsproxy` (TCP #853)
- `DNS-over-HTTPS` via `dnsproxy` (TCP #443)

For example, in Oracle Cloud we'll need to configure our Security List on our Virtual Cloud Network. Follow the steps below to get through this.

1. 

## 3. Set up DDNS
We need to use DDNS to identify our host by a domain name. If we used its IP, we would have to painstakingly update all client configurations in the event of the host being assigned a new IP.

For example, I have used No-IP for decades and it gets the job done. Follow the steps below to get through this.

1. 

## 2. Customize prior to installation
For brevity, the below are keywords that you can find-and-replace within the file in question. To expedite, when running `remote-init.sh` to install `a-hole`, these values are replaced. Placeholders are denoted by a prepended and postpended `!`, such as `!PLACEHOLDER!`
***
`DDNS` DDNS domain name that you registered with No-IP
- i.e. `"DDNS"` -> `"my.ddns.net"`

`DDNSUSER` Username of your account with No-IP
- i.e. `"DDNSUSER"` -> `"noipme"`

`DDNSPASS` Password of your account with No-IP
- i.e. `"DDNSPASS"` -> `"my1securepass!"`

`EMAIL` Your email address
- i.e. `"EMAIL"` -> `"me@gmail.com"`

`PIPASS` The password you want to use to access the Pihole admin page
- i.e. `"PIPASS"` -> `"mypip4ss"`

`PEERS` A comma-separated list of client peers that will connect to Wireguard for VPN access
- i.e. `"PEERS"` -> `"pc, pixel, iphone"`
 
The following files also have some other optional tuneables:
***
`docker-compose.yml`: Optionally, change `TZ` from America/New_York to your own timezone.

`unbound-dns.conf`: Optionally, change `forward-addr` from OpenDNS IPs to Internet DNS servers of your choice

## 3. Install
Run `remote-init.sh` from your local Linux shell which orchestrates various configurations of the cloud host instance to get it ready to run `a-hole`. Take care in inputting your parameters properly as arguments. Escape special characters (i.e. in passwords) and wrap your peer list in double quotes.

```
> ./remote-init.sh IP DDNS EMAIL DDNSUSER DNDSPASS PIPASS PEERS
> ./remote-init.sh  <the IP of your host instance>    i.e. 123.456.789.000
                    <DDNS domain name>                i.e. my.ddns.net
                    <your email address>              i.e. me@gmail.com
                    <your NOIP username>              i.e. noipme
                    <your NOIP password>              i.e. my1securepass\!
                    <your desired Pihole password>    i.e. mypip4ss
                    <comma-separated list of peers>   i.e. "pc, pixel, iphone"
> ./remote-init.sh 123.456.789.000 my.ddns.net me@gmail.com noipme my1securepass\! mypip4ss "pc, pixel, iphone"
```
> Once `remote-init.sh` has completed and you're SSH'd into your cloud host instance, you're up and running! Now you can use `control.py` to perform common operations...

Set or reset the password to login to pihole
```
> ./control.py pihole password <mypassword>
> ./control.py pihole password mYa-h0le!
  [✓] New password set
```
Bring `a-hole` up
```
> ./control.py - up
```
Bring `a-hole` down
```
> ./control.py - down
```
View logs of a container
```
> ./control.py <container> ?
> ./control.py certbot ?
Account registered.
Requesting a certificate...
```
Open an interactive shell to a container if it supports it
```
> ./control.py <container> /
> ./control.py nginx /
nginx > 
```
Run an arbitrary command in a running container
```
> ./control.py <container> - <arbitrary command>
> ./control.py nginx - echo "hi a-hole"
hi a-hole
```
## 4. How to configure some common clients
PC using Wireguard

- On the cloud host, run the following command to print out the Wireguard client configuration
    ```
    > ./control.py wg config <client name>
    > ./control.py wg config pc
    [Interface]
    Address = 10.1.1.3
    PrivateKey = 8Jzn+8E1OLkcbnuDkreBtaEk8Bvhj6HTQHv6zn4GK2Y=
    ListenPort = 51820
    DNS = 10.1.1.1

    [Peer]
    PublicKey = UnRXSLmmlcIU8uC2QUcO6Wxm9YVUCycVg9t4bBcY+CI=
    PresharedKey = Txrli+SFvQe4mR970/EqjCSgfy0A2/QpDhpKaNq/Mek=
    Endpoint = me.ddns.net:51820
    AllowedIPs = 10.1.0.0/16
    ```
- Copy all of the above lines including `[Interface]`
- Open Wireguard on your PC and `Add empty tunnel...`
- Paste the above into tunnel configuration, name it `a-hole`, and save it
- Activate `a-hole` and the client device is now up and running

Mobile using DNS-over-TLS
> Possible on Android devices but I believe iOS does not support DNS-over-TLS
- This depends on specific Android OS, but generally, open `Settings`
- Search settings for `Private DNS`, open this section of Settings
- Select `Private DNS provider hostname` and enter your DDNS domain name i.e. `me.ddns.net` 

Mobile using Wireguard
- On the cloud host, run the following command for a QR of the Wireguard client configuration
```
> ./control.py wg qr <client name>
> ./control.py wg qr mobile
PEER mobile QR code:

█████████████████████████████████████████████████████████████████████
█████████████████████████████████████████████████████████████████████
████ ▄▄▄▄▄ █ ▄▀▀▀▄ █▀▄█▀▄ ▄▄▄▄█▀▄▀███▀  ▄█  █▀ ▄▄  ▄▄██  █ ▄▄▄▄▄ ████
████ █   █ ███ ▀▀ ▄█▀▄█▀▀▀▄▄▄▄█▄▀▄▄█▀▀▄▄▄▄▄███▀ ▄▀█ █  ▄ █ █   █ ████
████ █▄▄▄█ █ ▀ ▄▀███▄▄██  ▄█ ▀██ ▄▄▄ █ ▄▀▄ ▄██ ▄▀▄ ▄▄▀ ▄██ █▄▄▄█ ████
████▄▄▄▄▄▄▄█ █ █▄█ █ ▀▄█▄▀▄█ ▀▄██ ▀█ ▀ ▀ ▀▄█ █▄▀ █▄█ █▄▀ █▄▄▄▄▄▄▄████
████▄▄▄▀█▄▄▀ ▄▀▄ █ ▀█ ▄  █ ▀▄█▄█  ▄▄ █▄▄▄ ▄▀▄█▄▄ ▀██ ▀▄▀▄ ▄▄ ▀▀▄▄████
█████▄█ █ ▄▀ ▄█▄  ▄███  ▀  ▄▄  ▄▄▀█ ▄▄▀▄█ ▀▄  ██▀█ ▄  ███ ▀█ ▄█▀ ████
████ █  █ ▄ ▀█ ▀▄█▄ ▄█ ██▀▄ ██ ▀█████ █▀ ▄▄ ▄ ▄█ █▄▄▄▀▄ ██▄▀▄▀▀▄█████
████▄▀██▄▀▄█▄  ▄▀ ▄█▄███▄█▀▄█  ▀▄▄▄▀ █ ▀▄▄▄  ▄▄▀█ ▀▄  █ ▄▄ ▀▄██▀ ████
██████ █ ▄▄█▄ ▄▀▀ ▄█▄█  ███▀▄█▄▀ █  ▄ ▄█▄▀▄▀▄ ██ █▄ ▄ █ ▄▀▄▀▄▀▀██████
████▀██ ▄█▄█▄█▄▀ ▄ █▄▀▀▀█ ▀▄ ▄█ █ ▄█ ▀█▄▄▀▀ ▀ █▄█▄█   █▄▀▀  ▀▀▄▀ ████
████▀▄ ▀ █▄▄▄   ▄ ▄ ▄▀▄ ▄▀  █    ▄ ▄  ▄ ▄▄█▄ ▀▄▄▄▄▄█ ▄▄ █ █ ▄▄▀▄ ████
████▀▀▄ ▄ ▄▀  █▀█▄▄▄▄█▀▄ █▀█▄▄▄ █ █▄ ▄▄▄ █▀▄▀▀▀▄ █▀▄█ ██ ▄█▄▀▀▄█ ████
████▄▄▄█▀▄▄▀▀███ ▄  ▄███▄▀▄▄█▄▀▄▄▀▄▀▀▄▄ ▄▀██ ▄█ ▄█▄█  ▄ █▀▄█  █ █████
████▄▄▄█ ▀▄ ▀ ▄▀▀██▀▄▄██▄  ▀  ▄▀▄ █▄▄█▀ ▀▄▀  ▀▀▄  ▀▄ ▄ █ ▄▀▄▄ ▄▀ ████
████▀▀█▄ ▄▄▄  ██▀▀ ▀▄█  ▄█ ▀██ ▄█ ▀▄ ▀█▀  █▄▄ █   █▄▄ █▀ ▄▄▄  ▄▄ ████
██████▀██ ▀█  ▀▀█▀█ ▄  ▄▄ ▄█▀ ▀▄ █▄█ █▄█▀ ▄▄ ▀▄▄▄▄█▀ ▀▄█ █ ▀  █ ▄████
████▀▀ ▀ ▄▄▄ ▄▀▄▀▄█  █▄ █ ▄▄▄█ ▀▄ ▄ ▄ █ ▄ ▄█ ▀▄ ▄▄▄▀ ██▀▄▄  ▄▀▄▄ ████
████▀▀▀ ▄▄▄█▀█▀ ▀▀▀ ▀ ▄  █▄▄▄▀ ▄  █▀▄▄▀▀▀▄█  ▀█▀▀▀█▄ ██▄▄█▄▄▀▀▄▀▄████
█████▀▀▀▄█▄ █▄██▀ █▀█▀ ███ ▀█     ██▀▀▄▄ █▄ ▄▄▄▄ █▄▀ ▄ ▄▀█ ██ ▀▀ ████
█████▀ ▀▄▄▄▄ █▄█▀▀█▄  ▄█ ▄ ▀▄██ ▄▀▄▀██ ▀▀ █  ██  █▀▄ ▀█▀ ▀▄▀  ██ ████
█████ █▄ ▄▄▀▀█▀▄ ▄█▀█ ▄  ▀▄██ ▄ ▀  ▀▄ ▄▀▄▀▄▀▄██▄ ▀██▄ ▄ ▀█▄▀▄▀██ ████
████▀█▄█▀ ▄▄ ▄██▄█▀▄ ▄▀ ▀▀ ▄▄█▀ ▀▄▄ █▄▄█ ██▄ ▄▄▀▀ ▄▀ ██▀▀▀ ▄█ █ ▄████
████ █▀█▀█▄██ █ █▀ ▀▄  ███  █▀ █▀▀ ▄▀ ▄█▄▀▄ ▄███  ▄█  ▄ █  ▀█ ▄  ████
████▄▄███▀▄█▀▀█ ▀▄▄▄  ██ █▀ ▄▀▄▄█ ▄▄█▄▀▀▀ █▀▀█ ▀▄▄█  ▄▀ ▀█ ▀▄▀██ ████
█████▀▄█▄ ▄█▄▀ ▀█ ▄█▄▀▄ ▄██▄▄▀  ██ ██ █▄▄▀▄█▄▀█ ▄█▄▀▄▀▄▄███▄▄█▀▀█████
████▀▀ ▄ ▄▄▄  ▀▄▄ ▀█▄▄▄██ ▄▄▄▄▄▄▀▀▄▄█▄█▄     ▄▀ ▀███ ▀▀█▀█ ▀ ██▀▄████
████▄▄▄▄██▄█▀█▀▀ ▄  ██▄ ██▄ ▄▄ ▄ ▄▄█ ▀▄ ▄▄█ ▄▄█▄▄█▄█▄██ ▀▄▄▄ ▀█  ████
████ ▄▄▄▄▄ █▀ ▄▄▀▀█ ▄█▀▀▄█ ▀▄ ██ ▀▄█ █▀▄ █▀█ █▀▄▀██  ▄█ █ ▀▄  ▄▄ ████
████ █   █ ██ ▄███▄█████▄▀▄▄█▄▀ ▄ ▄ ▄ █▀ █▄█▄ █▄▄▀█▄▄ █▄  ▄▄ ▄▀█▄████
████ █▄▄▄█ █ ▀█▄▀▀▄▀▄█ █▄▀▄█ ▀▄█▄▄▄▄▀▀█▄▀ ▀ ▀█▄▄  ▄▀  ▀█▄▀▄█▄██▄▄████
████▄▄▄▄▄▄▄█▄█▄█▄██▄▄█▄███▄▄▄█▄█▄█▄█▄█▄█▄▄▄▄▄▄▄█▄▄▄█▄██▄▄▄▄▄████▄████
█████████████████████████████████████████████████████████████████████
█████████████████████████████████████████████████████████████████████
```
- On your mobile device, install the Wireguard app
- Open the Wireguard app and tap the `+` in the corner
- Select `Scan from QR code`
- Point your camera at the QR, name it `a-hole`, and save it
- Enable `a-hole` and now this client is up and running
- You can optionally further configure your mobile device to automatically enable `a-hole` whenever the device is on