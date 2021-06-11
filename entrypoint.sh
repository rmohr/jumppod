#!/bin/sh
set -ex
watch 'cp authorized_keys_configmap/authorized_keys /tmp/authorized_keys && chown nonroot /tmp/authorized_keys && chmod 600 /tmp/authorized_keys && mv /tmp/authorized_keys authorized_keys/' > /dev/null 2>&1 &
ssh-keygen -A -f /home/nonroot && /usr/sbin/sshd -f ~/.ssh/sshd_config -D -e
