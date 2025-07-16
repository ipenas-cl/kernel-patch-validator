# Linux Kernel Quick Reference Card

## Patch Lifecycle
```
Write Code → Test → Create Patch → Check Style → Find Maintainers → Send → 
Wait for Feedback → Address Comments → Send v2 → ... → Accepted → Merged
```

## Must-Run Commands Before EVERY Submission
```bash
# 1. Style check
./scripts/checkpatch.pl --strict patch.patch

# 2. Build test
make -j$(nproc)

# 3. Find maintainers  
./scripts/get_maintainer.pl patch.patch

# 4. Verify applies cleanly
git checkout target-branch
git am patch.patch
```

## Commit Message Template
```
subsystem: component: One line summary (50-72 chars)

Paragraph explaining the problem. What doesn't work? What are the
symptoms? When does it happen? User-visible impact?

Technical explanation of the root cause and why this fix is correct.
Explain any non-obvious design decisions.

Fixes: 123456789abc ("subsystem: Original commit subject")
Cc: stable@vger.kernel.org # v5.10+
Link: https://lore.kernel.org/r/msgid@example.com
Reported-by: Reporter Name <email@example.com>
Tested-by: Tester Name <email@example.com>
Signed-off-by: Your Name <your@email.com>
---
v2: Address maintainer feedback about locking
v1: Initial submission

 path/to/file.c | 10 +++++-----
 1 file changed, 5 insertions(+), 5 deletions(-)
```

## Email Response Template
```
On Date, Reviewer Name wrote:
> Specific question or comment being addressed?

Your specific response here. Keep it technical and concise.

> Another point raised?

Another specific response.

Thanks for the review!
```

## Tree Selection Guide
| Type | Tree | Tag | When Open |
|------|------|-----|-----------|
| Bug fixes | net | [PATCH net] | Always |
| Features | net-next | [PATCH net-next] | Not during -rc |
| Staging | staging | [PATCH] | Always |
| Urgent fixes | mainline | [PATCH] | -rc only |

## Waiting Periods
- **Between patch versions**: 24 hours minimum (netdev mandatory)
- **Before pinging**: 1-2 weeks
- **Merge window**: ~2 weeks (no features)
- **Release cycle**: ~8-10 weeks total

## Critical Checkpoints
- [ ] Tabs not spaces (8 chars)
- [ ] 80 column preferred
- [ ] One change per patch
- [ ] Fixes: with 12+ char SHA
- [ ] Changelog after ---
- [ ] Used get_maintainer.pl
- [ ] Tested actual functionality
- [ ] No new warnings

## Red Flags to Avoid
1. Attachments → Use git send-email
2. HTML email → Plain text only  
3. Top posting → Inline responses
4. "See attached" → Inline patch
5. No testing → Always test
6. Mass CC → Target specific people
7. Arguments → Accept feedback gracefully
8. Hasty resubmit → Wait 24h minimum

## Emergency Fixes
```bash
# Revert a patch
git revert <commit>

# Fix email setup
git config sendemail.transferEncoding 8bit
git config sendemail.validate true

# Re-send (only if unchanged)
git send-email --subject-prefix="PATCH RESEND" patch.patch
```

## Subsystem Cheat Sheet

### Staging
- Focus: Cleanup only
- TODO file is king
- checkpatch.pl warnings = bugs
- No features until clean

### Networking (net/net-next)  
- Reverse Christmas tree
- 15 patch maximum
- 24h between versions
- Cover letter if 2+ patches

### Memory (mm)
- Performance data required
- CONFIG_DEBUG_VM testing
- Consider NUMA impacts
- /proc/meminfo changes noted

## Magic Incantations
```bash
# The perfect patch check
make clean && make -j$(nproc) && \
./scripts/checkpatch.pl --strict *.patch && \
echo "Ready to send!"

# Find what changed
git log --oneline --reverse origin/master..HEAD

# See patch statistics  
git format-patch -1 --stdout | diffstat

# Emergency abort send
Ctrl+C (during git send-email)
```

Keep this reference handy. Review before EVERY submission!