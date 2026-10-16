#!/bin/bash
set -e

: "${SSH_USERNAME:?"Error: SSH_USERNAME environment variable is not set."}"
: "${SSH_PASSWORD:?"Error: SSH_PASSWORD environment variable is not set."}"
: "${SSH_UID:?"Error: SSH_UID environment variable is not set."}"
: "${SSH_GID:?"Error: SSH_GID environment variable is not set."}"

if [ "$SSH_UID" -lt 1000 ]; then
  echo "Error: SSH_UID must be >= 1000." >&2
  exit 1
fi

if [ ! -d "/home/$SSH_USERNAME" ]; then
  echo "Error: /home/$SSH_USERNAME does not exist." >&2
  exit 1
fi

for u in $(getent passwd | awk -F: '$5 ~ /DOCKER_MANAGED/ {print $1}'); do
  userdel "$u" 2>/dev/null || true
done

if ! getent group "$SSH_GID" >/dev/null 2>&1; then
  groupadd -g "$SSH_GID" "$SSH_USERNAME" 2>/dev/null || true
fi
OCCUPANT=$(getent passwd "$SSH_UID" | cut -d: -f1 || true)
if [ -n "$OCCUPANT" ] && [ "$OCCUPANT" != "$SSH_USERNAME" ]; then
  userdel "$OCCUPANT" 2>/dev/null || true
fi
if ! getent group "$SSH_GID" >/dev/null 2>&1; then
  groupadd -g "$SSH_GID" "$SSH_USERNAME" 2>/dev/null || true
fi
useradd -c "DOCKER_MANAGED" -s /bin/bash -u "$SSH_UID" -g "$SSH_GID" -d "/home/$SSH_USERNAME" "$SSH_USERNAME"

echo "$SSH_USERNAME:$SSH_PASSWORD" | chpasswd

echo "$SSH_USERNAME ALL=(ALL) NOPASSWD: ALL" > "/etc/sudoers.d/$SSH_USERNAME"
chmod 440 "/etc/sudoers.d/$SSH_USERNAME"

mkdir -p /run/sshd
ssh-keygen -A
chmod 600 /etc/ssh/ssh_host_*_key
chmod 644 /etc/ssh/ssh_host_*_key.pub

cat > /etc/ssh/sshd_config.d/zcode.conf <<EOF
PasswordAuthentication yes
PermitRootLogin no
Subsystem sftp internal-sftp
PubkeyAuthentication yes
ClientAliveInterval 60
ClientAliveCountMax 3
EOF

exec /usr/sbin/sshd -D -e
