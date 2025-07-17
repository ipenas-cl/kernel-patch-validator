# Kernel Patch Validator

[![License: GPL v2](https://img.shields.io/badge/License-GPL%20v2-blue.svg)](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
[![GitHub Issues](https://img.shields.io/github/issues/ipenas-cl/kernel-patch-validator)](https://github.com/ipenas-cl/kernel-patch-validator/issues)

Validate patches before sending them to Linux kernel mailing lists.

After getting patches rejected multiple times by maintainers, I built this validator to catch the common mistakes that get patches rejected immediately.

## Quick Usage

```bash
# Just created a patch? Validate it!
git format-patch -1
./scripts/validate-patch.sh 0001-your-patch.patch

# Working on a patch series?
git format-patch -3 --cover-letter
./scripts/validate-series.sh .

# Looking for your first contribution?
./scripts/find-bugs.sh

# Not sure if you're ready to contribute?
./scripts/contribution-checklist.sh
```

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
│   ├── KERNEL_DEBUGGING_GUIDE.md      # Debug configs and tools
│   ├── KERNEL_TESTING_GUIDE.md        # Comprehensive testing guide
│   ├── LKMP_MENTORSHIP_GUIDE.md       # Linux Kernel Mentorship Program guide
│   ├── MENTORSHIP_COMMUNICATION.md    # Communication best practices
│   ├── SYSTEMATIC_DEBUGGING_WORKFLOW.md # Step-by-step debugging process
│   ├── COMMUNITY_ENGAGEMENT.md        # Diversity and inclusion guidelines
│   ├── DEVELOPER_LIFECYCLE.md         # Career paths from newcomer to maintainer
│   ├── GETTING_STARTED_GUIDE.md       # Complete newcomer's roadmap
│   └── KERNEL_QUICK_REFERENCE.md      # Quick reference
├── scripts/
│   ├── validate-patch.sh              # Automated validator
│   ├── pre-send-checklist.sh          # Interactive checklist
│   ├── quick-check.sh                 # 5-second sanity check
│   ├── test-patch.sh                  # Complete patch testing workflow
│   ├── find-bugs.sh                   # Automated bug finding for contributions
│   └── contribution-checklist.sh      # Interactive readiness assessment
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
- ✓ Build requirements analysis
- ✓ Single purpose patches
- ✓ Commit message quality
- ✓ Novice patterns detection
- ✓ Git workflow configuration
- ✓ Debug and testing practices
- ✓ Static analysis recommendations
- ✓ DCO compliance validation
- ✓ GPL-2.0 license checking
- ✓ CI and testing methodology validation
- ✓ Performance impact assessment

### test-patch.sh

Complete patch testing workflow:
- ✓ Safe patch application in test branch
- ✓ Automated compilation testing
- ✓ Static analysis with sparse/smatch
- ✓ Module compilation validation
- ✓ Change impact analysis
- ✓ Automatic cleanup on completion

### find-bugs.sh

Automated contribution opportunity finder:
- ✓ Spelling and grammar error detection
- ✓ Static analysis with sparse and checkpatch
- ✓ Missing .gitignore file identification
- ✓ Debug configuration recommendations
- ✓ Syzbot report integration
- ✓ Comprehensive analysis reporting

### contribution-checklist.sh

Interactive readiness assessment:
- ✓ Community engagement evaluation
- ✓ Technical setup verification
- ✓ Knowledge assessment with scoring
- ✓ Personalized action plan generation
- ✓ Integration with other tools

### pre-send-checklist.sh

Interactive checklist covering:
- Basic sanity checks
- Patch quality
- Format requirements
- Recipient validation
- Timing considerations
- Final preparations

## Getting Started

### For Complete Newcomers
```bash
# 1. Assess your readiness
./scripts/contribution-checklist.sh

# 2. Find contribution opportunities
./scripts/find-bugs.sh

# 3. Read the comprehensive guide
cat docs/GETTING_STARTED_GUIDE.md

# 4. Join the community (see guide for IRC/mailing list details)
```

### For New Contributors
```bash
# 1. Find your first bug to fix
./scripts/find-bugs.sh

# 2. Check you're ready
./scripts/contribution-checklist.sh

# 3. Follow the complete workflow below
```

## Common Workflows

### Single Patch
```bash
# 1. Create your patch
git format-patch -1

# 2. Test the patch thoroughly
./scripts/test-patch.sh 0001-my-patch.patch

# 3. Validate it
./scripts/validate-patch.sh 0001-my-patch.patch

# 4. Find maintainers
./scripts/get_maintainer.pl 0001-my-patch.patch

# 5. Run final checklist
./scripts/pre-send-checklist.sh

# 6. Send it
git send-email --to="maintainer@example.com" 0001-my-patch.patch
```

### Patch Series (v2)
```bash
# 1. Create series with cover letter
git format-patch -3 --cover-letter -v2

# 2. Edit cover letter using template
cp templates/cover-letter.template v2-0000-cover-letter.patch
# Edit...

# 3. Test and validate each patch
for patch in v2-*.patch; do
    ./scripts/test-patch.sh "$patch"
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

# Make scripts executable
cd ~/kernel-patch-validator
chmod +x scripts/*.sh

# Optional: Add to PATH for easy access
echo 'export PATH="$PATH:$HOME/kernel-patch-validator/scripts"' >> ~/.bashrc
source ~/.bashrc
```

## Quick Examples

### Example 1: Validate a Simple Spelling Fix
```bash
# After fixing a typo in drivers/staging/rtl8723bs/
git add -p  # Stage your changes
git commit -m "staging: rtl8723bs: fix spelling mistake 'recieve' -> 'receive'"
git format-patch -1

# Validate before sending
validate-patch.sh 0001-staging-rtl8723bs-fix-spelling-mistake.patch

# If all checks pass, send it
git send-email --to="Greg Kroah-Hartman <gregkh@linuxfoundation.org>" \
               --cc="linux-staging@lists.linux.dev" \
               0001-staging-rtl8723bs-fix-spelling-mistake.patch
```

### Example 2: Find Your First Contribution
```bash
# Find easy bugs to fix
cd ~/linux
find-bugs.sh

# Output will show:
# ✓ Found 23 spelling errors
# ✓ Found 45 checkpatch issues in staging  
# ✓ Found 12 untracked files in tools/

# Pick one and fix it
grep -n "recieve" drivers/staging/rtl8723bs/core/rtw_recv.c
# Fix the typo, then validate as shown above
```

### Example 3: Validate a Patch Series
```bash
# You've made 3 related changes
git format-patch -3 --cover-letter

# Edit the cover letter
vim 0000-cover-letter.patch

# Validate the entire series
validate-series.sh .

# Check individual patches too
for patch in 000*.patch; do
    validate-patch.sh "$patch"
done

# Send the series
git send-email 000*.patch
```

### Example 4: Debug a Rejected Patch
```bash
# Your patch was rejected for "multiple logical changes"
# Use the validator to understand why
validate-patch.sh rejected-patch.patch

# Output:
# ⚠ Single Purpose - Patch might be doing multiple things
# ✗ Commit Message - Commit message seems too short

# Split into separate patches
git reset HEAD~1
git add -p  # Stage only related changes
git commit -m "staging: driver: fix checkpatch warnings"
git add -p  # Stage other changes  
git commit -m "staging: driver: remove dead code"
```

### Example 5: Test Changes Before Submission
```bash
# After creating your patch
test-patch.sh 0001-my-changes.patch

# This will:
# - Apply patch in a test branch
# - Compile test the changes
# - Run sparse/smatch if available
# - Clean up automatically

# If compilation fails, fix and regenerate patch
```

## Real-World Examples

### Case Study: CamelCase Fix Rejection
```bash
# WRONG: Dan Carpenter rejected this for changing a runtime variable to const
git commit -m "staging: sm750fb: make g_fbmode const"

# Use the validator to catch this:
validate-patch.sh 0001-staging-sm750fb-make-g_fbmode-const.patch
# Would show: ⚠ Check if variable is modified at runtime

# RIGHT: Only fix the CamelCase issue
git commit -m "staging: sm750fb: fix CamelCase variable names"
```

### Case Study: Missing Changelog in v2
```bash
# Greg's bot rejected this:
Subject: [PATCH v2] staging: rtl8723bs: fix checkpatch warnings
---
 drivers/staging/rtl8723bs/core/rtw_efuse.c | 6 ------

# Validator catches this:
# ✗ Version Changelog - v2+ patches must have changelog after --- marker

# Fixed version:
Subject: [PATCH v2] staging: rtl8723bs: fix checkpatch warnings
---
v2: Split into separate patches as suggested by maintainer

 drivers/staging/rtl8723bs/core/rtw_efuse.c | 6 ------
```

### Case Study: Date Problem (2025 Bug)
```bash
# System clock was wrong, patches showed year 2025
# Validator immediately catches this:
# ✗ Date Check - Patch contains future date (2025). Fix your system date!

# Fix your system date first:
sudo ntpdate pool.ntp.org
# Then regenerate patches
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

## Related Resources

- [Greg KH's kernel-tutorial](https://github.com/gregkh/kernel-tutorial) - Essential tutorial on writing and submitting kernel patches
- [Greg KH's kernel-development](https://github.com/gregkh/kernel-development) - Presentation on how Linux kernel is developed
- [The kernel development process](https://www.kernel.org/doc/html/latest/process/)
- [Linux Kernel Mentorship Program](https://wiki.linuxfoundation.org/lkmp)
- [kernelnewbies.org](https://kernelnewbies.org/) - Resources for kernel beginners

This validator complements these resources by automating the checks that
catch common mistakes before submission.

## Acknowledgments

- Linux kernel maintainers for their patience with novice contributors
- The kernel documentation team for comprehensive guides
- The staging tree maintainers for providing a learning environment

---

Remember: It's better to be slow and correct than fast and wrong!