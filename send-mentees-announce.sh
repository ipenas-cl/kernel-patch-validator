#!/bin/bash
# Send announcement to linux-kernel-mentees

ANNOUNCE="/Users/ignacioenlosmercados/kernel-patch-validator/promotion/announce-mentees-list.txt"

echo "=== Sending Announcement to linux-kernel-mentees ==="
echo
echo "This will announce the kernel-patch-validator to new contributors"
echo

git send-email \
  --to="linux-kernel-mentees@lists.linuxfoundation.org" \
  "$ANNOUNCE"