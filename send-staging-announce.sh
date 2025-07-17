#!/bin/bash
# Send announcement to linux-staging list

ANNOUNCE="/Users/ignacioenlosmercados/kernel-patch-validator/promotion/staging-list-announce.txt"

echo "=== Sending Announcement to linux-staging ==="
echo
echo "This will announce to staging driver contributors"
echo "Greg KH maintains this list - many new contributors here"
echo

git send-email \
  --to="linux-staging@lists.linux.dev" \
  "$ANNOUNCE"