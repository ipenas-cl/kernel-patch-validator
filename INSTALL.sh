#!/bin/bash
# Quick installer for kernel patch validator

echo "Installing Kernel Patch Validator..."

# Add to PATH
if ! grep -q "kernel-patch-validator/scripts" ~/.bashrc; then
    echo 'export PATH="$HOME/kernel-patch-validator/scripts:$PATH"' >> ~/.bashrc
    echo "✓ Added to PATH"
fi

# Add git aliases
if ! grep -q "gitconfig.kernel" ~/.gitconfig; then
    echo "[include]" >> ~/.gitconfig
    echo "    path = ~/.gitconfig.kernel" >> ~/.gitconfig
    cp ~/.gitconfig.kernel.bak ~/.gitconfig.kernel 2>/dev/null || true
    echo "✓ Added git aliases"
fi

# Create symlinks for easy access
ln -sf ~/kernel-patch-validator/scripts/validate-patch.sh ~/bin/kvalidate 2>/dev/null || true
ln -sf ~/kernel-patch-validator/scripts/quick-check.sh ~/bin/kcheck 2>/dev/null || true
ln -sf ~/kernel-patch-validator/scripts/pre-send-checklist.sh ~/bin/kchecklist 2>/dev/null || true

echo ""
echo "Installation complete!"
echo ""
echo "Available commands:"
echo "  kvalidate <patch>    - Full validation"
echo "  kcheck <patch>       - Quick sanity check"  
echo "  kchecklist           - Interactive pre-send checklist"
echo ""
echo "Git aliases added:"
echo "  git validate <patch> - Run validator"
echo "  git precheck <patch> - Quick check"
echo "  git fp              - Format patch"
echo "  git se              - Send email"
echo ""
echo "Restart your shell or run: source ~/.bashrc"