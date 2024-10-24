#!/bin/bash
# Create 'dev' user
useradd dev
mkdir -p /home/dev/.ssh
chmod 700 /home/dev/.ssh
cp /home/centos/.ssh/authorized_keys /home/dev/.ssh/
chmod 600 /home/dev/.ssh/authorized_keys
chown -R dev:dev /home/dev/.ssh

# Format and mount disks
for device in /dev/xvdf /dev/xvdg; do
  mkfs -t ext4 $device
done

mkdir /data
mount /dev/xvdf /data
echo '/dev/xvdf /data ext4 defaults 0 2' >> /etc/fstab

mkdir /data1
mount /dev/xvdg /data1
echo '/dev/xvdg /data1 ext4 defaults 0 2' >> /etc/fstab