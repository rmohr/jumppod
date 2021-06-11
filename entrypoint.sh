#!/bin/sh
set -ex
# copy files areound a little before starting sshd to fulfill it's ownership
# and permission requirements on files. configmaps and secrests are not
# flexible enough for sshd out of box.

# prepare host keys
mkdir -p tmp/host-keys
cp host_keys_secret/* tmp/host-keys/
chown nonroot tmp/host-keys/*
chmod 600 tmp/host-keys/*
cp tmp/host-keys/* etc/ssh/

# perodically syncronize the authorized_keys file
watch 'cp authorized_keys_configmap/authorized_keys /tmp/authorized_keys && chown nonroot /tmp/authorized_keys && chmod 600 /tmp/authorized_keys && mv /tmp/authorized_keys authorized_keys/' > /dev/null 2>&1 &

# run sshd
/usr/sbin/sshd -f ~/.ssh/sshd_config -D -e
