# Kernel Patch Validator

[![License: GPL v2](https://img.shields.io/badge/License-GPL%20v2-blue.svg)](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
[![GitHub Issues](https://img.shields.io/github/issues/ipenas-cl/kernel-patch-validator)](https://github.com/ipenas-cl/kernel-patch-validator/issues)

Validate patches before sending them to Linux kernel mailing lists.

After getting patches rejected multiple times by maintainers, I built this validator to catch the common mistakes that get patches rejected immediately.

## Quick Start

```bash
# Validate a single patch
./scripts/validate-patch.sh my-patch.patch

# Run interactive pre-send checklist
./scripts/pre-send-checklist.sh

# Create patch with template
cp templates/commit-message.template my-commit.txt
# Edit my-commit.txt, then:
git commit -F my-commit.txt
```

## Directory Structure

```
kernel-patch-validator/
├── docs/
│   ├── KERNEL_CONTRIBUTION_GUIDE.md    # Complete guide
│   ├── KERNEL_ANTIPATTERNS.md         # What NOT to do
│   └── KERNEL_QUICK_REFERENCE.md      # Quick reference
├── scripts/
│   ├── validate-patch.sh              # Automated validator
│   └── pre-send-checklist.sh          # Interactive checklist
├── templates/
│   ├── commit-message.template        # Perfect commit message
│   ├── email-response.template        # How to reply to reviews
│   └── cover-letter.template          # For patch series
└── README.md                          # This file
```

## Features

### validate-patch.sh

Automated checks for:
- ✓ Future dates (2025 bug)
- ✓ Signed-off-by presence
- ✓ Subject line format
- ✓ Version changelog placement
- ✓ Fixes: tag format
- ✓ Cc: stable format
- ✓ checkpatch.pl compliance
- ✓ Patch applies cleanly
- ✓ Single purpose patches
- ✓ Commit message quality
- ✓ Novice patterns detection

### pre-send-checklist.sh

Interactive checklist covering:
- Basic sanity checks
- Patch quality
- Format requirements
- Recipient validation
- Timing considerations
- Final preparations

## Common Workflows

### Single Patch
```bash
# 1. Create your patch
git format-patch -1

# 2. Validate it
./scripts/validate-patch.sh 0001-my-patch.patch

# 3. Find maintainers
./scripts/get_maintainer.pl 0001-my-patch.patch

# 4. Run final checklist
./scripts/pre-send-checklist.sh

# 5. Send it
git send-email --to="maintainer@example.com" 0001-my-patch.patch
```

### Patch Series (v2)
```bash
# 1. Create series with cover letter
git format-patch -3 --cover-letter -v2

# 2. Edit cover letter using template
cp templates/cover-letter.template v2-0000-cover-letter.patch
# Edit...

# 3. Validate each patch
for patch in v2-*.patch; do
    ./scripts/validate-patch.sh "$patch"
done

# 4. Send series
git send-email --to="maintainer@example.com" v2-*.patch
```

### Responding to Review
```bash
# Use the template
cp templates/email-response.template response.txt
# Edit response.txt with your replies
# Send using your email client (keep plain text!)
```

## Installation

```bash
# Clone the repository
git clone https://github.com/ipenas-cl/kernel-patch-validator.git ~/kernel-patch-validator

# Run the installer
cd ~/kernel-patch-validator
./INSTALL.sh

# Restart your shell or source your bashrc
source ~/.bashrc
```

## Tips

1. **Always validate before sending** - It takes 30 seconds and saves embarrassment
2. **Use templates** - Don't write commit messages from scratch
3. **Read the docs** - Especially KERNEL_ANTIPATTERNS.md
4. **Be patient** - Wait 24h between versions, 1 week before pinging
5. **Test everything** - "Compile tested only" = "I'm lazy"

## The Golden Rules

1. One logical change per patch
2. Explain WHY, not WHAT
3. Use git send-email (no attachments!)
4. Run checkpatch.pl --strict
5. Actually test your changes
6. Check your system date isn't 2025
7. Put v2+ changelogs after ---
8. Use get_maintainer.pl for recipients
9. Wait patiently for reviews
10. Thank reviewers, even harsh ones

## Troubleshooting

**"Patch contains future date (2025)"**
- Fix your system date/time
- Regenerate the patch

**"checkpatch.pl failed"**
- Read /tmp/checkpatch.out
- Fix ALL warnings for staging drivers
- Use --strict for best results

**"Patch doesn't apply cleanly"**
- Wrong base tree?
- Rebase on latest upstream
- Check git remote configuration

## Contributing

Found a bug or have a suggestion? Please contribute!

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

This toolkit is meant to help everyone avoid novice mistakes.

## Background

Built this after my patches kept getting rejected for basic formatting issues and style problems. Got tired of the back-and-forth with maintainers like Dan Carpenter and Greg KH over things that should be caught before submitting.

Each check here is based on an actual mistake I made and had to fix.

## License

GPL-2.0 (same as Linux kernel) - see [LICENSE](LICENSE) file.

## Acknowledgments

- Linux kernel maintainers for their patience with novice contributors
- The kernel documentation team for comprehensive guides
- The staging tree maintainers for providing a learning environment

---

Remember: It's better to be slow and correct than fast and wrong!