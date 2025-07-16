#!/bin/bash
# Setup kernel development environment

set -e

echo "=== Kernel Development Environment Setup ==="
echo ""

# Git configuration
echo "Configuring git for kernel development..."

git config --global user.name "${GIT_NAME:-Your Name}"
git config --global user.email "${GIT_EMAIL:-your.email@example.com}"

# Email settings
git config --global sendemail.smtpserver "${SMTP_SERVER:-smtp.gmail.com}"
git config --global sendemail.smtpserverport "${SMTP_PORT:-587}"
git config --global sendemail.smtpencryption tls
git config --global sendemail.confirm auto
git config --global sendemail.chainreplyto false
git config --global sendemail.thread true
git config --global sendemail.transferEncoding 8bit
git config --global sendemail.validate true

# Useful aliases
git config --global alias.fp 'format-patch --subject-prefix="PATCH"'
git config --global alias.fpn 'format-patch --subject-prefix="PATCH net"' 
git config --global alias.fpnn 'format-patch --subject-prefix="PATCH net-next"'
git config --global alias.fps 'format-patch --subject-prefix="PATCH staging"'
git config --global alias.se 'send-email --suppress-cc=self'

# Editor settings
git config --global core.editor "${EDITOR:-vim}"

echo "✓ Git configured"
echo ""

# Create useful directories
echo "Creating directory structure..."
mkdir -p ~/kernel/{patches,sent,reviews,scripts}
echo "✓ Directories created"
echo ""

# Download kernel
echo "Do you want to clone the kernel? [y/N]: "
read -r response

if [[ "$response" =~ ^[Yy]$ ]]; then
    echo "Cloning mainline kernel (this will take a while)..."
    git clone https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git ~/kernel/linux
    
    echo "Adding common remotes..."
    cd ~/kernel/linux
    git remote add linux-next https://git.kernel.org/pub/scm/linux/kernel/git/next/linux-next.git
    git remote add staging https://git.kernel.org/pub/scm/linux/kernel/git/gregkh/staging.git
    git remote add net https://git.kernel.org/pub/scm/linux/kernel/git/netdev/net.git
    git remote add net-next https://git.kernel.org/pub/scm/linux/kernel/git/netdev/net-next.git
    
    echo "✓ Kernel cloned and remotes added"
fi

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Next steps:"
echo "1. Update GIT_NAME and GIT_EMAIL environment variables"
echo "2. Configure your SMTP settings for git send-email"
echo "3. Read ~/kernel-patch-validator/docs/KERNEL_CONTRIBUTION_GUIDE.md"
echo "4. Always run validate-patch.sh before sending!"
echo ""
echo "Happy hacking!"