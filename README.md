# `a*hole`
A cloud-hosted blackhole for ads with a smörgåsbord of secure interfaces.

(tldr at the end)

# Why?
As a pet project in 2019, I built all of this incrementally and a lot less cleanly, but it worked like a charm for me and mine. In Summer 2022, the public cloud VM in which I had built all of this - with limited version control - imploded. Virtually all was lost and the DNS on my devices was relegated to service from the likes of Comcast and spectated by the Chinese Communist Party.

So, I decided to do it again but do it in a way that's entirely reproduceable so when the next VM implodes, it would be a matter of minutes until I had everything up and running again on a new host.

# Objectives
The goal of this is to provide a low-maintenance setup to provide secure ad-blocking DNS service with a spectrum of access methods for a handful of known users and their devices.

Downtime is acceptable and in order to keep the installation within the bounds of the Oracle Cloud free tier, there is limited fault tolerance and redundancy. Expect an installation to have issues semi-annually that can be resolved with minimal debugging or maybe just a reinstallation or an update. Not worried about random users accessing the non-VPN endpoints so long as it's limited and without apparent malice.

# Overview of components
## [Ubuntu](https://ubuntu.com/)
Ubuntu on an AMD processor is the platform of choice and where I'm certain this works. Ubuntu because it's universal; AMD because it's one of the two flavors of free-tier hardware in Oracle Cloud's free tier and ARM is a lot less reliable for Docker builds at this point in time.

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

## [DuckDNS](https://www.duckdns.org/)
DuckDNS is a very simple, straightforward, reliable, popular DDNS provider, so we'll use it to manage our DDNS domain names to access `a-hole`.

## [ddclient](https://ddclient.net/)
ddclient provides updates to many DDNS services to keep the host machine IP and the DDNS domain names in sync. 

## Support scripts
There are also a few scripts which make everything a snap:\
`remote-init.sh` streamlines setup\
`dns-test.sh` aids in debugging various DNS functions\
`control.py` simplifies control of an active installation

# tldr;
Ad-blocking DNS-over-TLS, DNS-over-HTTPS, and DNS-via-VPN. Instructions to get it running are below.

>Prep time: 11 min\
>Baking time: 4 min

# How-to...
# 1. Get cloud infrastructure
You'll need a cloud infrastructure provider where you can:
- Instantiate a host instance
- Configure the firewall rules to allow ports to pass through from the Internet into the instance

For example, Oracle Cloud as it has an "Always Free" tier that allows me to run this for free. Follow the steps below to check this off.

1. https://cloud.oracle.com.
2. `Sign Up` for an Oracle Cloud Infrastrcture account.
3. Choose a region that's reasonably proximate to where you live.

# 2. Set up firewall rules
We've got all of the firewall management within the host handled, but we'll need to make sure that our cloud infrastructure provider allows a few ports through to our host.

For example, in Oracle Cloud we'll need to configure our Security List on our Virtual Cloud Network. Follow the steps below to check this off.

1. In Oracle Cloud, in the search entry at the top, query for `Virtual Cloud Networks` and navigate into the service (hereforth referred to as VCN).
2. In the VCNs page, tap the button to `Create VCN`.
3. Specify a name. Specify an `IPv4 CIDR block` of `10.0.0.0/16`. Save.
4. Tap the link for the new VCN.
5. On the VCN detail page, tap `Create Subnet`.
6. Specify a name. Specify an `IPv4 CIDR block` of `10.0.0.0/24`. Save.
7. Tap the link for the new Subnet.
8. On the Subnet page at the bottom, tap the link for `Default Security List for ...`.
9. Repeatedly `Add Ingress Rules` for the ports you want to make accessible.
10. Adding TCP/80 example, on the add ingress rule page, `Source Type` = `CIDR`, `Source CIDR` = `0.0.0.0/0`, `IP Protocol` = `TCP`, `Source Port Range` = `''`, `Destination Port Range` = `80`, `Description` = `LetsEncrypt challenge`.
11. When done, `Ingress Rules` should look something like this.
![Rules](/media/oci-vpn-sl.png)

Ports are as follows...

| Description  | Protocol | Port | Mandatory? |
| - | - | - | - |
| SSH  | TCP | 22 | Yes (pre-enabled)
| LetsEncrypt Challenge  | TCP | 80 | Yes
| Wireguard | UDP | 51820 | Yes
| DNS-over-HTTPS | TCP | 443
| DNS-over-TLS | TCP & UDP | 853
| DNS-over-QUIC | TCP & UDP | 1853
| DNSCrypt | TCP & UDP | 2853

# 3. Create a host instance
We need our cloud host instance where `a-hole` will run.

For example, in Oracle Cloud we'll need to create and configure a new instance. Follow the steps below to check this off.

1. In Oracle Cloud, in the search entry at the top, query for `Instances` and navigate into the service.
2. In the Instances page, tap the `Create Instance` button.
3. Specify a name.
4. In the `Image and shape` section, tap `Edit` and `Change image` to `Ubuntu`. Select image.
5. Below in the `Image and shape` section, `Change shape` to `VM.Standard.E2.1.Micro` which is under the `Specialty and previous generation` tab. Select shape.
6. In the `Add SSH keys` section, specify a key pair however you wish in order to access the host once it's built. If you're not familiar with SSH, take a moment to learn how to generate keys and what role they play in SSH.
7. At the very bottom of the page, `Create`.
8. On the `Instance details` page, after a little while, a public IP will be assigned and populate the `Instance access` section next to `Public IP address`. Copy and save this IP address somewhere; it'll be needed later.

# 4. Set up DDNS
We need to use DDNS to identify our host by a domain name. If we used its IP, we would have to painstakingly update all client configurations in the event of the host being assigned a new IP.

For example, you can up a DDNS domain name via DuckDNS. Follow the steps below to check this off.

1. Go to https://duckdns.org.
2. Register an account.
3. In the middle of the page, there is an entry for a new domain name and a button to `add domain`. Enter yours.
![New](/media/duckdns-new.png)
4. Your domain name should now be listed in the middle of the page. Above, there is a section that lists account details and included in that is `token`. Copy and save the token value somewhere; it'll be needed later.
![Token](/media/duckdns-token.png)

# 5. (Optional) Customizations prior to installation
When running `remote-init.sh`, placeholder values are replaced with parameters provided. Placeholders in files are denoted by postpended `!!!`, such as `PLACEHOLDER!!!`. The following files also have some other optional tuneables:

`docker-compose.yml`: Change `TZ` from America/New_York to your own timezone.

`unbound.conf`: Change `forward-addr` from OpenDNS IPs to Internet DNS servers of your choice.

Peruse other files if you'd like and there may be some other modifications you'd like to make, but I've designed most other things to be tightly coupled.

# 6. Install
Run `remote-init.sh` from your local Linux shell which orchestrates various configurations of the cloud host instance to get it ready to run `a-hole`. Take care in inputting your parameters properly as arguments. Escape special characters (i.e. in passwords) and wrap your peer list in double quotes:

```
> ./remote-init.sh IP DDNS EMAIL DDNSUSER DNDSPASS PIPASS PEERS
> ./remote-init.sh  <the IP of your host instance>    i.e. 123.456.789.000
                    <DDNS domain name>                i.e. my.duckdns.org
                    <your email address>              i.e. me@gmail.com
                    <your NOIP username>              i.e. noipme
                    <your NOIP password>              i.e. my1securepass\!
                    <your desired Pihole password>    i.e. mypip4ss
                    <comma-separated list of peers>   i.e. "pc, pixel, iphone"
> ./remote-init.sh 123.456.789.000 my.duckdns.org me@gmail.com noipme my1securepass\! mypip4ss "pc, pixel, iphone"
```
> Once `remote-init.sh` has completed and you're SSH'd into your cloud host instance, you're up and running! Now you can use `control.py` to perform common operations...

SSH into your host instance from your local machine:
```
> ssh ubuntu@<your DDNS domain name>
> ssh ubuntu@my.duckdns.org
```
Set or reset the password to login to pihole:
```
> ./control.py pihole password <mypassword>
> ./control.py pihole password mYa-h0le!
  [✓] New password set
```
Bring `a-hole` up:
```
> ./control.py - up
```
Bring `a-hole` down:
```
> ./control.py - down
```
View logs of a container:
```
> ./control.py <container> ?
> ./control.py certbot ?
Account registered.
Requesting a certificate...
```
Open an interactive shell to a container (if it supports a shell):
```
> ./control.py <container> /
> ./control.py nginx /
nginx > 
```
Run an arbitrary command in a running container:
```
> ./control.py <container> - <arbitrary command>
> ./control.py  - echo "hi a-hole"
hi a-hole
```
# 7. How to configure some common clients
## PC using Wireguard
1. On the cloud host, run the following command to print out the Wireguard client configuration:
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
2. Copy all of the above lines including `[Interface]`.
3. Open Wireguard on your PC and `Add empty tunnel...`.
4. Paste the above into tunnel configuration, name it `a-hole`, and save it.
5. Activate `a-hole` and the client device is now up and running.

## Mobile using DNS-over-TLS
> Possible on Android devices but I believe iOS does not support DNS-over-TLS.
1. This depends on specific Android OS, but generally, open `Settings`.
2. Search settings for `Private DNS`, open this section of Settings.
3. Select `Private DNS provider hostname` and enter your DDNS domain name i.e. `my.duckdns.org`.

## Mobile using Wireguard
1. On the cloud host, run the following command for a QR of the Wireguard client configuration:
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
2. On your mobile device, install the Wireguard app.
3. Open the Wireguard app and tap the `+` in the corner.
4. Select `Scan from QR code`.
5. Point your camera at the QR, name it `a-hole`, and save it.
6. Enable `a-hole` and now this client is up and running.
7. You can optionally further configure your mobile device to automatically enable `a-hole` whenever the device is on.

## To add additional clients later
1. Open `docker-compose.yml` for editing on your host instance.
2. Find the environment variable `PEERS:` under the `Wireguard` section.
3. Postpend the name of your new peer(s) onto this comma-separated list, then save it.
4. On your host instance, run the following command:
```
> ./control.py - up
```
5. View the QR code or configuration of your new Wireguard client:
```
> ./control.py wg qr <new client name>
> ./control.py wg config <new client name>
```
