# Reddit r/kernel Post

**Title**: I built a tool to validate kernel patches after getting rejected multiple times

**Content**:

Hey r/kernel,

After having patches rejected by Greg KH and Dan Carpenter for basic formatting issues, I decided to build a comprehensive validator that catches these mistakes before submission.

## What it does:
- 21+ automated checks based on real rejection feedback
- Catches the infamous "2025 date bug" (wrong system clock)
- Validates changelog placement for v2+ patches
- Checks DCO compliance, subject format, single logical change
- Integrates checkpatch.pl with better reporting

## Additional tools included:
- **find-bugs.sh** - Automatically finds contribution opportunities (spelling errors, checkpatch issues)
- **test-patch.sh** - Safe patch testing workflow
- **validate-series.sh** - Validates entire patch series
- **contribution-checklist.sh** - Interactive readiness assessment

## Example output:
```
$ validate-patch.sh 0001-staging-fix-typo.patch
======================================
   KERNEL PATCH VALIDATOR v1.0
======================================

=== Basic Patch Checks ===
✓ Date Check
✓ Signed-off-by (DCO)
✓ Subject Format
✗ Version Changelog - v2+ patches must have changelog after --- marker

=== Code Style Checks ===
✓ checkpatch.pl
✓ Patch Apply
⚠ Build Test Required
```

## Real catches from my patches:
1. Dan Carpenter rejected my patch for changing runtime variable to const (validator now warns about this)
2. Greg's bot rejected v2 patch missing changelog (validator enforces changelog after ---)
3. System date was 2025, patches got rejected (validator immediately catches this)

GitHub: https://github.com/ipenas-cl/kernel-patch-validator

Each check is based on actual mistakes I made. Hope it helps others avoid the frustration of basic rejections!

Built this in pure bash with no dependencies beyond standard kernel tools. Feedback and contributions welcome!