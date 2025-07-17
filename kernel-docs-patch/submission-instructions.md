# Submitting patch-validator to kernel documentation

## Overview
This patch adds patch-validator to the official kernel documentation under Documentation/dev-tools/. This will give the tool official visibility and help new contributors find it.

## Pre-submission checklist

1. **Clone linux-next or mainline kernel**
```bash
git clone https://git.kernel.org/pub/scm/linux/kernel/git/next/linux-next.git
cd linux-next
```

2. **Apply and test the patch**
```bash
git am ~/kernel-patch-validator/kernel-docs-patch/0001-Documentation-Add-patch-validator-to-dev-tools.patch
make htmldocs  # Build documentation to verify formatting
```

3. **Run checkpatch**
```bash
./scripts/checkpatch.pl --strict ~/kernel-patch-validator/kernel-docs-patch/0001-Documentation-Add-patch-validator-to-dev-tools.patch
```

4. **Get maintainers**
```bash
./scripts/get_maintainer.pl ~/kernel-patch-validator/kernel-docs-patch/0001-Documentation-Add-patch-validator-to-dev-tools.patch
```

Expected output:
- Jonathan Corbet <corbet@lwn.net> (maintainer:DOCUMENTATION)
- linux-doc@vger.kernel.org (open list:DOCUMENTATION)
- linux-kernel@vger.kernel.org (open list)

## Sending the patch

### Option 1: git send-email (recommended)
```bash
git send-email \
  --to="Jonathan Corbet <corbet@lwn.net>" \
  --cc="linux-doc@vger.kernel.org" \
  --cc="linux-kernel@vger.kernel.org" \
  ~/kernel-patch-validator/kernel-docs-patch/0001-Documentation-Add-patch-validator-to-dev-tools.patch
```

### Option 2: Email client
1. Use **plain text mode** (no HTML)
2. To: Jonathan Corbet <corbet@lwn.net>
3. Cc: linux-doc@vger.kernel.org, linux-kernel@vger.kernel.org
4. Subject: [PATCH] Documentation: Add patch-validator to dev-tools
5. Paste entire patch content (from "From " to the end)

## Expected timeline
- Initial review: 1-2 weeks
- If accepted: Merged in next merge window
- If changes requested: Address feedback and send v2

## Alternative approaches if documentation patch is not accepted

1. **LWN article**: Contact LWN editors about writing an article
2. **kernelnewbies.org wiki**: Add to their tools page
3. **kernel.org blog**: Submit a blog post about the tool
4. **Conference talk**: Submit to Linux Plumbers, Kernel Summit, or FOSDEM

## Follow-up actions

After patch is accepted:
1. Update README to mention inclusion in kernel docs
2. Add kernel docs link to GitHub repository
3. Monitor for user feedback and bug reports
4. Consider adding tool to distributions (Debian, Fedora packages)

## Sample cover letter (if requested)

Subject: [PATCH 0/1] Add patch-validator to kernel documentation

Hi Jonathan,

This patch adds documentation for patch-validator, a tool that helps kernel
contributors validate their patches before submission. The tool has been
actively used by new contributors to catch common mistakes that lead to
patch rejections.

The validator performs 21+ automated checks based on real rejection feedback
from maintainers, helping improve patch quality and reduce maintainer workload.

The tool is maintained at:
https://github.com/ipenas-cl/kernel-patch-validator

Thanks for considering this addition to the kernel documentation.

Best regards,
Ignacio Peña