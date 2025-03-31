#!/bin/sh

echo "--- A-HOLE basic updates for the host machine"
sudo DEBIAN_FRONTEND=noninteractive apt --yes --allow-change-held-packages update
sudo DEBIAN_FRONTEND=noninteractive apt --yes --allow-change-held-packages upgrade
sudo DEBIAN_FRONTEND=noninteractive apt --yes --allow-change-held-packages autoremove
sudo DEBIAN_FRONTEND=noninteractive apt --yes --allow-change-held-packages autoclean

echo "--- A-HOLE install dependent packages"
sudo DEBIAN_FRONTEND=noninteractive apt install --yes --allow-change-held-packages python3 docker.io docker-compose

echo "--- A-HOLE configure host machine for unattended upgrades"
sudo DEBIAN_FRONTEND=noninteractive apt install --yes --allow-change-held-packages unattended-upgrades apt-listchanges bsd-mailx
sudo dpkg-reconfigure -fnoninteractive -plow unattended-upgrades

echo "--- A-HOLE add user to docker group to avoid sudo"
sudo usermod -aG docker ubuntu

echo "--- A-HOLE configure docker to start on machine reboot"
sudo systemctl enable docker.service
sudo systemctl enable containerd.service

echo "--- A-HOLE setting timezone"
sudo timedatectl set-timezone America/Detroit

echo "--- A-HOLE sudo schedule host machine to reboot once a week on Wednesday morning at 6:00"
sudo crontab -l | grep 'reboot' && echo '--- A-HOLE reboot in crontab' || (sudo crontab -l 2>/dev/null; echo "0 4 * * 6 /usr/sbin/reboot") | sudo crontab -

echo "--- A-HOLE schedule certbot to run once a week on Wednesday morning at 6:10"
crontab -l | grep 'certbot' && echo '--- A-HOLE certbot in crontab' || (crontab -l 2>/dev/null; echo "10 4 * * 6 /usr/bin/docker-compose -f ~/a-hole/docker-compose.yml up certbot") | crontab -

echo "--- A-HOLE schedule duckdns IP update hourly at 5 minutes past the hour"
crontab -l | grep 'cjpi.duckdns' && echo '--- A-HOLE duckdns in crontab' || (crontab -l 2>/dev/null; echo "5 * * * * curl -L \"https://www.duckdns.org/update?domains=DDNS!!!&token=DDNSPASS!!!&verbose=true\"") | crontab -
