# Complete Linux Kernel Contribution Guide

## Table of Contents
1. [Prerequisites and Setup](#prerequisites-and-setup)
2. [Kernel Development Process](#kernel-development-process)
3. [Coding Style Rules](#coding-style-rules)
4. [Creating Perfect Patches](#creating-perfect-patches)
5. [Email and Communication](#email-and-communication)
6. [Testing Requirements](#testing-requirements)
7. [Handling Feedback](#handling-feedback)
8. [Common Novice Mistakes](#common-novice-mistakes)
9. [Subsystem-Specific Rules](#subsystem-specific-rules)
10. [Tools and Commands](#tools-and-commands)

---

## Prerequisites and Setup

### Git Configuration
```bash
# Essential git config
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
git config --global sendemail.confirm auto
git config --global sendemail.chainreplyto false
git config --global sendemail.thread true

# Add Link: tag automatically
cat >> .git/hooks/post-commit << 'EOF'
#!/bin/sh
sha=$(git rev-parse HEAD)
echo "Link: https://lore.kernel.org/r/$sha" >> $(git rev-parse --git-dir)/COMMIT_EDITMSG
EOF
chmod +x .git/hooks/post-commit
```

### Email Setup
```bash
# For Gmail
git config --global sendemail.smtpserver smtp.gmail.com
git config --global sendemail.smtpserverport 587
git config --global sendemail.smtpencryption tls
git config --global sendemail.smtpuser your.email@gmail.com
```

---

## Kernel Development Process

### Release Cycle
- **2-week merge window**: New features accepted
- **6-8 week stabilization**: Only fixes accepted (-rc releases)
- **Release**: Linus releases new version
- **Stable updates**: Maintained by Greg KH

### Which Tree to Target
```
mainline (Linus)     → Big changes, new features (during merge window)
linux-next           → Integration testing
subsystem trees      → Subsystem-specific development
  ├─ net-next       → Networking features (open during merge window)
  ├─ net            → Networking fixes (always open)
  └─ staging        → Staging driver cleanup (always open)
```

---

## Coding Style Rules

### Critical Rules
```c
/* GOOD: 8-character tabs */
static int function(int arg)
{
	if (condition) {
		do_something();
		return 0;
	}
	return -EINVAL;
}

/* BAD: spaces instead of tabs */
static int function(int arg)
{
    if (condition) {
        do_something();
        return 0;
    }
    return -EINVAL;
}
```

### Naming Conventions
```c
/* GOOD */
int user_count;
void update_stats(void);
#define MAX_BUFFER_SIZE 4096

/* BAD */
int usrCnt;        // No camelCase
void UpdateStats(); // No MixedCase
#define max_size 4096  // Macros should be UPPERCASE
```

### Line Length
- **Preferred**: 80 columns
- **Hard limit**: 100 columns (only when readability improves)

---

## Creating Perfect Patches

### Commit Message Format
```
subsystem: component: Short one-line description

Longer explanation of the problem and why this change is needed.
Describe user-visible impact if any. Use imperative mood.

Technical details of the implementation go here. Explain design
decisions if they're not obvious.

Fixes: 123456789abc ("previous: commit: subject")
Cc: stable@vger.kernel.org # v5.4+
Link: https://lore.kernel.org/r/previous-discussion
Reported-by: Reporter Name <reporter@example.com>
Signed-off-by: Your Name <your.email@example.com>
---
v3: Fixed coding style issues pointed out by maintainer
v2: Addressed review comments about error handling
v1: Initial submission

 drivers/staging/driver.c | 42 +++++-----
 1 file changed, 25 insertions(+), 17 deletions(-)
```

### Patch Generation
```bash
# Single patch
git format-patch -1 --subject-prefix="PATCH net"

# Patch series with cover letter
git format-patch -3 --cover-letter --subject-prefix="PATCH v2"

# Check your patch
./scripts/checkpatch.pl --strict 0001-your-patch.patch
```

### Sending Patches
```bash
# Find maintainers
./scripts/get_maintainer.pl 0001-your-patch.patch

# Send single patch
git send-email --to="maintainer@example.com" \
               --cc="subsystem@vger.kernel.org" \
               0001-your-patch.patch

# Send series
git send-email --to="maintainer@example.com" \
               --cc="subsystem@vger.kernel.org" \
               00*.patch
```

---

## Email and Communication

### Proper Email Format
```
> Original question from maintainer
>
> Why did you choose this approach?

I chose this approach because:
1. It minimizes memory allocation
2. It's consistent with existing code patterns
3. Performance testing showed 10% improvement

> What about error handling?

Error handling follows the standard kernel pattern:
- Check for allocation failures
- Use goto for cleanup
- Return proper error codes
```

### NEVER DO THIS:
```
Thanks for the feedback! I'll fix it.

> Original question from maintainer
> Why did you choose this approach?
> What about error handling?
```

---

## Testing Requirements

### Before Submitting ANY Patch
```bash
# 1. Compile test (minimum)
make allmodconfig
make -j$(nproc)

# 2. Sparse check
make C=1 drivers/your/driver.o

# 3. Smatch check
make CHECK="smatch -p=kernel" C=1 drivers/your/driver.o

# 4. Checkpatch
./scripts/checkpatch.pl --strict your.patch

# 5. For netdev patches
make htmldocs  # Check for documentation warnings
```

### Debug Options
```
CONFIG_DEBUG_KERNEL=y
CONFIG_PROVE_LOCKING=y
CONFIG_DEBUG_ATOMIC_SLEEP=y
CONFIG_KASAN=y
```

---

## Handling Feedback

### Response Timeline
- **Initial feedback**: Respond within 24-48 hours
- **Resubmission**: Wait at least 24 hours (netdev: mandatory)
- **No response**: Wait 1-2 weeks before gentle ping
- **Rejection**: Thank reviewer, fix issues, resubmit as v2

### Good Response Example
```
On Mon, Jul 15, 2024 at 10:30:00AM -0700, Maintainer wrote:
> This change looks risky. What testing did you do?

I tested this on:
- x86_64 with CONFIG_DEBUG_KERNEL=y
- ARM64 on real hardware
- Ran the subsystem test suite (all passed)

> Also, the error path looks wrong.

You're right, I missed freeing the buffer. Will fix in v2.

Thanks for the review!
```

---

## Common Novice Mistakes

### 1. Wrong Patch Format
```bash
# WRONG - Attachments
"Please find my patch attached"

# RIGHT - Inline
git send-email patch.patch
```

### 2. Missing Fixes Tag
```bash
# WRONG
"This fixes a bug introduced in commit 123456"

# RIGHT
Fixes: 123456789abc ("subsystem: Original commit subject")
```

### 3. Top-Posting
```
# WRONG
I'll fix it in v2.

> Original email below...

# RIGHT
> Specific question?

Specific answer.

> Another question?

Another answer.
```

### 4. Wrong Tree
```bash
# WRONG - Feature during -rc
[PATCH] net: Add new feature  # Sent during -rc6

# RIGHT - Fix during -rc
[PATCH net] net: Fix memory leak in driver
```

### 5. Multiple Logical Changes
```bash
# WRONG - One patch doing multiple things
"Fix checkpatch warnings and add new feature"

# RIGHT - Separate patches
[PATCH 1/2] driver: Fix checkpatch warnings
[PATCH 2/2] driver: Add new feature
```

### 6. Bad Version Changelog
```
# WRONG - In commit message
v2: Fixed issues

# RIGHT - After --- marker
Signed-off-by: Name <email>
---
v2: 
- Fixed memory leak in error path  
- Added missing locking as suggested by maintainer
- Rebased on latest net-next
```

### 7. Improper Stable Tag
```
# WRONG
Cc: stable  # Missing email
Cc: stable@vger.kernel.org  # Missing version

# RIGHT
Cc: stable@vger.kernel.org # v5.10+
```

### 8. Not Following Subsystem Rules
```c
/* WRONG - Netdev requires reverse Christmas tree */
static int func(void)
{
	int ret;
	struct long_structure_name *ptr;
	unsigned long flags;
	u8 val;
}

/* RIGHT - Reverse Christmas tree */
static int func(void)
{
	struct long_structure_name *ptr;
	unsigned long flags;
	int ret;
	u8 val;
}
```

### 9. Reposting Too Quickly
```bash
# WRONG
[PATCH] Fix issue      # Monday 10am
[PATCH v2] Fix issue   # Monday 2pm

# RIGHT  
[PATCH] Fix issue      # Monday 10am
[PATCH v2] Fix issue   # Tuesday 10am (24h minimum)
```

### 10. Not Using get_maintainer
```bash
# WRONG - Guessing maintainers
git send-email --to="linux-kernel@vger.kernel.org"

# RIGHT - Use the script
./scripts/get_maintainer.pl patch.patch
git send-email --to="actual-maintainer@example.com"
```

---

## Subsystem-Specific Rules

### Netdev (Networking)
```bash
# Subject tags
[PATCH net]      # Bug fixes (always open)
[PATCH net-next] # New features (closed during -rc)
[PATCH bpf]      # BPF fixes
[PATCH bpf-next] # BPF features

# Special rules
- Maximum 15 patches per series
- Reverse Christmas tree declarations
- 24 hour minimum between reposts
- Cover letter MANDATORY for 2+ patches
```

### Staging
```bash
# Focus areas
- checkpatch.pl cleanup
- Remove unnecessary code  
- Fix TODO items
- No new features until cleanup done

# Example TODO format
TODO:
- fix checkpatch warnings
- remove unnecessary typedefs  
- use standard kernel APIs
```

### MM (Memory Management)
```bash
# Special requirements
- Test with CONFIG_DEBUG_VM=y
- Include /proc/meminfo changes if relevant
- Performance data required for optimizations
- Consider NUMA effects
```

---

## Tools and Commands

### Essential Tools
```bash
# Style checking
./scripts/checkpatch.pl --strict patch.patch

# Find maintainers  
./scripts/get_maintainer.pl -f drivers/net/ethernet/intel/

# Generate compile_commands.json
./scripts/clang-tools/gen_compile_commands.py

# Kernel build with all debug
make allmodconfig
./scripts/config --enable DEBUG_KERNEL
make olddefconfig && make -j$(nproc)
```

### Useful git aliases
```bash
git config --global alias.fp 'format-patch --subject-prefix="PATCH"'
git config --global alias.fpn 'format-patch --subject-prefix="PATCH net"'
git config --global alias.se 'send-email --suppress-cc=self'
```

### Verification Workflow
```bash
# 1. Create patch
git fp -1

# 2. Check style
./scripts/checkpatch.pl --strict 00*.patch

# 3. Verify it applies
git checkout mainline/master
git am 00*.patch

# 4. Build test
make -j$(nproc) 

# 5. Find maintainers
./scripts/get_maintainer.pl 00*.patch > maintainers.txt

# 6. Send
git se --to-cmd="./scripts/get_maintainer.pl --norolestats" 00*.patch
```

---

## Regression Rules

### Linus's Rule
> "If a change results in user programs breaking, it's a bug in the kernel. 
> We never EVER blame the user programs."

### Handling Regressions
1. **Report immediately** when found
2. **Bisect** to find the problematic commit  
3. **Cc the commit author** in the report
4. **Fix or revert** within 2-3 weeks max
5. **Use regzbot** for tracking

```
#regzbot introduced: 123456789abc
#regzbot title: Network driver crashes on resume
```

---

## Final Checklist

Before EVERY submission:
- [ ] Patch applies cleanly to correct tree
- [ ] Checkpatch.pl passes with no warnings
- [ ] Compiles without warnings
- [ ] Commit message explains WHY not just WHAT
- [ ] Proper Fixes: tag if fixing a bug
- [ ] Cc: stable if fix should be backported
- [ ] Used get_maintainer.pl for recipients
- [ ] For v2+: changelog after --- marker
- [ ] Tested the actual change works
- [ ] One logical change per patch

Remember: It's better to over-communicate than under-communicate, but be concise and technical.