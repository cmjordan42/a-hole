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

echo "--- A-HOLE schedule host machine to reboot once a week on Wednesday morning"
crontab -l | grep 'reboot' && echo 'cron reboot exists' || (crontab -l 2>/dev/null; echo "0 6 * * 3 sudo /usr/sbin/reboot") | crontab -
