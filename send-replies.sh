#!/bin/bash
# Send replies to Greg and Jonathan

echo "=== Sending Replies ==="
echo

echo "1. Sending reply to Greg KH..."
git send-email \
  --in-reply-to="<ZppSfKGao4PQvRJd@kroah.com>" \
  /Users/ignacioenlosmercados/kernel-patch-validator/responses/reply-to-greg.txt

echo
echo "2. Sending reply to Jonathan Corbet..."
git send-email \
  --in-reply-to="<87wmjy92r6.fsf@trenco.lwn.net>" \
  /Users/ignacioenlosmercados/kernel-patch-validator/responses/reply-to-jonathan.txt

echo
echo "Replies sent!"