# Linux Kernel Anti-patterns: What NOT to Do

## Email Anti-patterns That Scream "Novice"

### 1. The "Attached Patch"
```
WRONG:
Subject: Fix for driver bug

Hi,
Please find my patch attached.
Thanks!

RIGHT:
[PATCH] staging: rtl8723bs: Fix memory leak in error path

<patch content inline in email>
```

### 2. The "No Context Response"
```
WRONG:
Fixed in v2.

RIGHT:
On Tue, Jul 16, 2024 at 10:00:00AM +0200, Dan Carpenter wrote:
> The error handling looks broken here.

You're right, I'm missing a kfree() in the error path. Fixed in v2.

> Also, why are you using GFP_ATOMIC?

This function can be called from interrupt context via the timer callback,
so GFP_KERNEL would be inappropriate here.
```

### 3. The "Shotgun Submit"
```
WRONG:
To: linux-kernel@vger.kernel.org
Cc: <nobody>

RIGHT:
To: <specific maintainer from get_maintainer.pl>
Cc: <subsystem list>, <other reviewers>
```

## Patch Anti-patterns

### 1. The "Kitchen Sink Patch"
```
WRONG:
Subject: [PATCH] Fix driver issues

This patch fixes checkpatch warnings, adds a new feature,
updates documentation, and removes dead code.

RIGHT:
[PATCH 1/4] driver: Fix checkpatch warnings
[PATCH 2/4] driver: Remove dead code  
[PATCH 3/4] driver: Add new feature X
[PATCH 4/4] Documentation: Update driver.rst
```

### 2. The "Mystery Fixes"
```
WRONG:
This fixes a bug in the driver.

RIGHT:
The driver fails to release the DMA buffer when initialization
fails, causing a memory leak. This can eventually lead to OOM
conditions on systems with limited memory.

This was found by kmemleak:
unreferenced object 0xffff88810a2b0000 (size 4096):
  comm "modprobe", pid 1234, jiffies 4294901234
  ...

Fixes: abcd1234567 ("driver: Add DMA support")
```

### 3. The "Time Traveler"
```
WRONG:
Date: Mon, 15 Jul 2025 10:00:00 +0500

RIGHT:  
Date: Mon, 15 Jul 2024 10:00:00 +0500
```

## Behavioral Anti-patterns

### 1. The "Impatient Pinger"
```
WRONG:
Monday 9am: [PATCH] Fix issue
Monday 2pm: "Did anyone see my patch?"
Tuesday: [PATCH RESEND] Fix issue
Wednesday: "Why is nobody reviewing this?"

RIGHT:
Week 1: [PATCH] Fix issue
Week 2: <silence>
Week 3: "Gentle ping on this patch"
```

### 2. The "Argue with Maintainer"
```
WRONG:
"I disagree with your feedback. My way is better because..."

RIGHT:
"I see your point about the locking. Would it be acceptable if I
used RCU here instead? That would address your concern about
scalability while still fixing the race condition."
```

### 3. The "Lazy Tester"
```
WRONG:
"Compile tested only"

RIGHT:
"Tested on x86_64 and arm64 hardware with CONFIG_DEBUG_KERNEL=y.
Ran the subsystem test suite with no regressions. Also tested
the specific error path using fault injection."
```

## Code Anti-patterns

### 1. The "Space Cadet"
```c
WRONG:
    if (condition) {
        do_something();
    }

RIGHT:
	if (condition) {
		do_something();
	}
```

### 2. The "Comment Novelist"
```c
WRONG:
/* 
 * This function is called to initialize the driver.
 * It takes a pointer to the device structure and
 * returns 0 on success or negative error code.
 * First it allocates memory, then it sets up the
 * hardware registers...
 */
static int init_driver(struct device *dev)

RIGHT:
/* Initialize hardware and allocate resources */
static int init_driver(struct device *dev)
```

### 3. The "Typedef Abuser"
```c
WRONG:
typedef struct {
	int field;
} my_struct_t;

RIGHT:
struct my_struct {
	int field;
};
```

## Version Control Anti-patterns

### 1. The "Changelog Hider"
```
WRONG:
Subject: [PATCH v3] Fix driver bug

Fixed issues from review.

Signed-off-by: Me <me@example.com>

RIGHT:
Subject: [PATCH v3] driver: Fix null pointer dereference

<proper commit message>

Signed-off-by: Me <me@example.com>
---
v3: Add locking around list manipulation (suggested by maintainer)
v2: Check for NULL before dereferencing
v1: Initial submission
```

### 2. The "Series Spammer"
```
WRONG:
[PATCH 01/47] Fix typo
[PATCH 02/47] Fix another typo
...
[PATCH 47/47] Fix yet another typo

RIGHT:
[PATCH 1/3] driver: Fix documentation typos
[PATCH 2/3] driver: Fix comment typos  
[PATCH 3/3] driver: Fix Kconfig typos
```

## Testing Anti-patterns

### 1. The "Works on My Machine"
```
WRONG:
"Tested on my laptop"

RIGHT:
"Tested on x86_64 with KASAN, PROVE_LOCKING, and DEBUG_ATOMIC_SLEEP
enabled. Also cross-compiled and tested on arm64."
```

### 2. The "Ignore Warnings"
```
WRONG:
<sends patch that adds compiler warnings>

RIGHT:
make W=1 drivers/staging/driver.o  # Check no new warnings
```

## Communication Anti-patterns

### 1. The "Ghost"
```
WRONG:
<Send patch>
<Receive feedback>
<Disappear forever>

RIGHT:
<Send patch>
<Receive feedback>
"Thanks for the review, will address in v2"
<Send v2 within reasonable time>
```

### 2. The "Bulk Submitter"
```
WRONG:
git send-email --to=everyone@earth.com *.patch

RIGHT:
./scripts/get_maintainer.pl --norolestats patch.patch
git send-email --to=<maintainer> --cc=<list> patch.patch
```

### 3. The "Format Disaster"
```
WRONG:
HTML email
Quoted-printable encoding  
Line wrapped at 72 chars
Tabs converted to spaces

RIGHT:
Plain text
No encoding
No line wrapping
Tabs preserved
```

## Instant Novice Indicators

1. **Sending patches as attachments**
2. **HTML email or format=flowed**
3. **No Signed-off-by line**
4. **Fixes: tag with short SHA** (use 12+ chars)
5. **Top-posting responses**
6. **"Fixed coding style" as entire commit message**
7. **Mixing whitespace and functional changes**
8. **Cc: stable without version**
9. **Not using get_maintainer.pl**
10. **Arguing about rejected patches**
11. **[PATCH RESEND] within 24 hours**
12. **Patches during merge window for -next**
13. **v2 without changelog**
14. **"Please apply" in commit message**
15. **Multiple emails for one patch series**

Remember: The kernel community values competence, clarity, and respect for process. Taking time to do things correctly is always better than rushing and looking like a novice.