#!/bin/bash
# Script to send kernel documentation patch

PATCH_FILE="../kernel-docs-patch/0001-Documentation-Add-patch-validator-to-dev-tools.patch"

echo "=== Kernel Documentation Patch Submission ==="
echo
echo "This will send the patch to add patch-validator to official kernel docs."
echo
echo "Recipients:"
echo "  To: Jonathan Corbet <corbet@lwn.net> (Documentation maintainer)"
echo "  Cc: linux-doc@vger.kernel.org"
echo "  Cc: linux-kernel@vger.kernel.org"
echo
echo "Make sure you have:"
echo "  1. Configured git send-email"
echo "  2. Valid SMTP settings"
echo
read -p "Ready to send? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    git send-email \
        --to="Jonathan Corbet <corbet@lwn.net>" \
        --cc="linux-doc@vger.kernel.org" \
        --cc="linux-kernel@vger.kernel.org" \
        "$PATCH_FILE"
else
    echo "Cancelled. When ready, run:"
    echo "git send-email --to=\"Jonathan Corbet <corbet@lwn.net>\" --cc=\"linux-doc@vger.kernel.org\" --cc=\"linux-kernel@vger.kernel.org\" $PATCH_FILE"
fi