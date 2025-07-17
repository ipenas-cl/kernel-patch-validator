#!/bin/bash
# Send documentation patch to kernel

PATCH="/Users/ignacioenlosmercados/kernel-patch-validator/kernel-docs-patch/0001-Documentation-Add-patch-validator-to-dev-tools.patch"

echo "=== Sending Kernel Documentation Patch ==="
echo
echo "Patch: $PATCH"
echo "To: Jonathan Corbet <corbet@lwn.net>"
echo "Cc: linux-doc@vger.kernel.org, linux-kernel@vger.kernel.org"
echo

# Send the patch
git send-email \
  --to="Jonathan Corbet <corbet@lwn.net>" \
  --cc="linux-doc@vger.kernel.org" \
  --cc="linux-kernel@vger.kernel.org" \
  "$PATCH"

echo
echo "Patch sent! Monitor responses at:"
echo "- https://lore.kernel.org/linux-doc/"
echo "- Your email inbox"
echo
echo "Next steps:"
echo "1. Wait for feedback (usually 1-2 weeks)"
echo "2. If accepted, it will be merged in next window"
echo "3. If changes requested, address and send v2"