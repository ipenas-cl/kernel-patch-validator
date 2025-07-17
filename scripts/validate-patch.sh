#!/bin/bash
# Kernel Patch Validator
# By Ignacio Peña - July 2024

# Don't exit on error - we want to check all issues
set +e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PATCH_FILE="$1"
KERNEL_DIR="${KERNEL_DIR:-$(pwd)}"
ERRORS=0
WARNINGS=0

# Check if patch file provided
if [ -z "$PATCH_FILE" ]; then
    echo -e "${RED}ERROR: No patch file provided${NC}"
    echo "Usage: $0 <patch-file> [kernel-directory]"
    exit 1
fi

if [ ! -f "$PATCH_FILE" ]; then
    echo -e "${RED}ERROR: Patch file '$PATCH_FILE' not found${NC}"
    exit 1
fi

echo "======================================"
echo "   KERNEL PATCH VALIDATOR v1.0"
echo "======================================"
echo "Patch: $PATCH_FILE"
echo "Kernel: $KERNEL_DIR"
echo ""

# Function to check for errors
check_error() {
    local test_name="$1"
    local result="$2"
    local message="$3"
    
    if [ "$result" -ne 0 ]; then
        echo -e "${RED}✗ $test_name${NC}"
        echo "  $message"
        ((ERRORS++))
        return 1
    else
        echo -e "${GREEN}✓ $test_name${NC}"
        return 0
    fi
}

# Function to check for warnings
check_warning() {
    local test_name="$1"
    local result="$2"
    local message="$3"
    
    if [ "$result" -ne 0 ]; then
        echo -e "${YELLOW}⚠ $test_name${NC}"
        echo "  $message"
        ((WARNINGS++))
        return 1
    else
        echo -e "${GREEN}✓ $test_name${NC}"
        return 0
    fi
}

echo "=== Basic Patch Checks ==="

# 1. Check for future dates
CURRENT_YEAR=$(date +%Y)
NEXT_YEAR=$((CURRENT_YEAR + 1))
if grep -E "Date:.*20[0-9][0-9]" "$PATCH_FILE" | grep -E "20(2[6-9]|[3-9][0-9])" > /dev/null; then
    check_error "Date Check" 1 "Patch contains future date (beyond $CURRENT_YEAR). Fix your system date!"
else
    check_error "Date Check" 0 ""
fi

# 2. Check for Signed-off-by (DCO compliance)
if ! grep -q "^Signed-off-by: .* <.*@.*>" "$PATCH_FILE"; then
    check_error "Signed-off-by (DCO)" 1 "Missing Signed-off-by line - required for DCO compliance"
else
    # Check DCO format is proper
    SOB_LINE=$(grep "^Signed-off-by:" "$PATCH_FILE" | tail -1)
    if echo "$SOB_LINE" | grep -q "^Signed-off-by: .* <.*@.*\..*>$"; then
        check_error "Signed-off-by (DCO)" 0 ""
    else
        check_error "Signed-off-by (DCO)" 1 "Invalid Signed-off-by format - must include full name and valid email"
    fi
fi

# 3. Check subject line format
SUBJECT=$(grep "^Subject: " "$PATCH_FILE" | head -1)
if echo "$SUBJECT" | grep -q "^Subject: \[PATCH.*\] [a-z0-9_/-]*: "; then
    check_error "Subject Format" 0 ""
else
    check_error "Subject Format" 1 "Subject should be: [PATCH] subsystem: lowercase description"
fi

# 4. Check for version changelog placement
if grep -q "^Subject: \[PATCH v[0-9]" "$PATCH_FILE"; then
    # This is a v2+ patch, must have changelog after ---
    if ! awk '/^---$/{f=1} f&&(/^Changes in [vV][0-9]:/ || /^[vV][0-9]:/) {found=1; exit} END{exit !found}' "$PATCH_FILE"; then
        check_error "Version Changelog" 1 "v2+ patches must have changelog after --- marker"
    else
        check_error "Version Changelog" 0 ""
    fi
else
    echo -e "${GREEN}✓ Version Changelog (v1 patch)${NC}"
fi

# 5. Check Fixes: tag format
if grep -q "^Fixes: " "$PATCH_FILE"; then
    if grep -E "^Fixes: [0-9a-f]{12,}" "$PATCH_FILE" | grep -q '(".*")$'; then
        check_error "Fixes Tag" 0 ""
    else
        check_error "Fixes Tag" 1 "Fixes: tag must have 12+ char SHA and commit subject"
    fi
fi

# 6. Check Cc: stable format
if grep -q "^Cc: stable" "$PATCH_FILE"; then
    if grep -q "^Cc: stable@\(vger.kernel.org\|kernel.org\)" "$PATCH_FILE"; then
        check_error "Stable Tag" 0 ""
    else
        check_error "Stable Tag" 1 "Format: Cc: stable@kernel.org or stable@vger.kernel.org"
    fi
fi

echo ""
echo "=== Code Style Checks ==="

# Skip if kernel directory doesn't exist
if [ ! -d "$KERNEL_DIR" ] || [ ! -f "$KERNEL_DIR/scripts/checkpatch.pl" ]; then
    echo -e "${YELLOW}⚠ Skipping code checks (kernel dir not found)${NC}"
else
    # 7. Run checkpatch.pl
    echo "Running checkpatch.pl..."
    if "$KERNEL_DIR/scripts/checkpatch.pl" --strict "$PATCH_FILE" > /tmp/checkpatch.out 2>&1; then
        check_error "checkpatch.pl" 0 ""
    else
        check_error "checkpatch.pl" 1 "See /tmp/checkpatch.out for details"
        # Show first few errors
        head -n 10 /tmp/checkpatch.out | sed 's/^/  /'
    fi
    
    # 8. Check if patch applies cleanly
    echo "Checking if patch applies..."
    cd "$KERNEL_DIR"
    if git apply --check "$PATCH_FILE" 2>/tmp/apply.err; then
        check_error "Patch Apply" 0 ""
    else
        check_error "Patch Apply" 1 "Patch doesn't apply cleanly"
        head -n 5 /tmp/apply.err | sed 's/^/  /'
    fi
    
    # 9. Check build requirements for modified files
    echo "Checking build impact..."
    MODIFIED_FILES=$(grep "^diff --git" "$PATCH_FILE" | awk '{print $4}' | sed 's|^b/||')
    BUILD_REQUIRED=0
    
    for file in $MODIFIED_FILES; do
        if [[ "$file" == *.c ]] || [[ "$file" == *.h ]] || [[ "$file" == *Makefile* ]] || [[ "$file" == *Kconfig* ]]; then
            BUILD_REQUIRED=1
            break
        fi
    done
    
    if [ "$BUILD_REQUIRED" -eq 1 ]; then
        check_warning "Build Test Required" 1 "This patch modifies buildable files - compile test required"
        echo "  Build commands:"
        echo "    make allmodconfig && make -j\$(nproc)"
        echo "    make C=1 # for sparse checking"
    else
        check_warning "Build Test Required" 0 ""
    fi
fi

echo ""
echo "=== License and Compliance Checks ==="

# 10. Check for GPL-2.0 compliance in new files
NEW_FILES=$(grep "^diff --git" "$PATCH_FILE" | grep "/dev/null" | awk '{print $4}' | sed 's|^b/||')
if [ -n "$NEW_FILES" ]; then
    MISSING_LICENSE=0
    for file in $NEW_FILES; do
        if [[ "$file" == *.c ]] || [[ "$file" == *.h ]]; then
            # Check if patch content includes SPDX license
            if ! grep -A 20 "^+++ b/$file" "$PATCH_FILE" | grep -q "SPDX-License-Identifier.*GPL-2.0"; then
                MISSING_LICENSE=1
                break
            fi
        fi
    done
    
    if [ "$MISSING_LICENSE" -eq 1 ]; then
        check_warning "GPL-2.0 License" 1 "New .c/.h files should include SPDX-License-Identifier: GPL-2.0"
        echo "  Add to top of new files: // SPDX-License-Identifier: GPL-2.0"
    else
        check_warning "GPL-2.0 License" 0 ""
    fi
fi

echo ""
echo "=== Content Checks ==="

# 11. Check for mixed changes
DIFF_SECTIONS=$(grep "^diff --git" "$PATCH_FILE" | wc -l)
CHANGE_TYPES=0

# Count different types of changes
grep -A10 "^Subject: " "$PATCH_FILE" | grep -qi "fix" && ((CHANGE_TYPES++)) || true
grep -A10 "^Subject: " "$PATCH_FILE" | grep -qi "add\|implement\|introduce" && ((CHANGE_TYPES++)) || true  
grep -A10 "^Subject: " "$PATCH_FILE" | grep -qi "cleanup\|style\|checkpatch" && ((CHANGE_TYPES++)) || true
grep -A10 "^Subject: " "$PATCH_FILE" | grep -qi "remove\|delete" && ((CHANGE_TYPES++)) || true

if [ "$CHANGE_TYPES" -gt 1 ]; then
    check_warning "Single Purpose" 1 "Patch might be doing multiple things"
else
    check_warning "Single Purpose" 0 ""
fi

# 12. Check commit message quality
MSG_LINES=$(awk '/^Subject:/{f=1} /^---$/{f=0} f' "$PATCH_FILE" | grep -v "^Subject:\|^$\|^Signed-off-by:\|^Fixes:\|^Cc:" | wc -l)
if [ "$MSG_LINES" -lt 3 ]; then
    check_warning "Commit Message" 1 "Commit message seems too short (explain WHY not just WHAT)"
else
    check_warning "Commit Message" 0 ""
fi

# 13. Check for common novice patterns
NOVICE_PATTERNS=0

# Check for "please apply"
grep -qi "please apply\|please merge" "$PATCH_FILE" && ((NOVICE_PATTERNS++)) || true

# Check for personal notes
grep -q "TODO\|FIXME\|XXX\|WIP" "$PATCH_FILE" && ((NOVICE_PATTERNS++)) || true

# Check for console output in commit message
grep -q "^\[.*\]$\|^$.*#" "$PATCH_FILE" && ((NOVICE_PATTERNS++)) || true

if [ "$NOVICE_PATTERNS" -gt 0 ]; then
    check_warning "Novice Patterns" 1 "Found patterns that suggest inexperience"
else
    check_warning "Novice Patterns" 0 ""
fi

echo ""
echo "=== Git Workflow Checks ==="

# 14. Check git commit best practices
if [ -f "$KERNEL_DIR/.git/config" ]; then
    cd "$KERNEL_DIR"
    
    # Check if user.name and user.email are set
    if ! git config user.name >/dev/null 2>&1; then
        check_warning "Git User Config" 1 "git config user.name not set"
    elif ! git config user.email >/dev/null 2>&1; then
        check_warning "Git User Config" 1 "git config user.email not set"
    else
        check_warning "Git User Config" 0 ""
    fi
    
    # Check for send-email configuration
    if ! git config sendemail.smtpserver >/dev/null 2>&1; then
        check_warning "Git Send-email Config" 1 "git send-email not configured (see docs/KERNEL_CONTRIBUTION_GUIDE.md)"
    else
        check_warning "Git Send-email Config" 0 ""
    fi
    
    # Check if this appears to be a proper kernel git repo
    if git remote get-url origin 2>/dev/null | grep -qi "torvalds/linux\|kernel/git"; then
        check_warning "Git Remote" 0 ""
    else
        check_warning "Git Remote" 1 "Not a standard kernel git repository"
    fi
fi

echo ""
echo "=== Debugging and Testing Checks ==="

# 15. Check for debug configuration mentions
if grep -q "CONFIG_DEBUG" "$PATCH_FILE"; then
    check_warning "Debug Config" 0 ""
else
    check_warning "Debug Config" 1 "Consider mentioning debug configs used (CONFIG_DEBUG_KERNEL, etc.)"
fi

# 16. Check for testing information
TESTING_KEYWORDS="tested|compile|build|load|run|verify|check"
if grep -Ei "$TESTING_KEYWORDS" "$PATCH_FILE"; then
    check_warning "Testing Info" 0 ""
else
    check_warning "Testing Info" 1 "Consider adding testing information to commit message"
fi

# 17. Check for sparse/smatch mention in complex patches
if [ "$DIFF_SECTIONS" -gt 3 ]; then
    if grep -qi "sparse\|smatch" "$PATCH_FILE"; then
        check_warning "Static Analysis" 0 ""
    else
        check_warning "Static Analysis" 1 "Complex patches should mention sparse/smatch testing"
    fi
fi

echo ""
echo "=== CI and Testing Validation ==="

# 19. Check for testing methodology information
TESTING_METHODS="boot|dmesg|stress|parallel|compile|CI|build-bot|kernelci|0-day"
if grep -Ei "$TESTING_METHODS" "$PATCH_FILE"; then
    check_warning "Testing Methodology" 0 ""
else
    check_warning "Testing Methodology" 1 "Consider describing testing performed (boot test, stress test, CI validation)"
fi

# 20. Check for performance impact assessment
PERF_KEYWORDS="performance|benchmark|regression|time|speed|latency"
LARGE_CHANGE=$(echo "$DIFF_SECTIONS" | awk '{if($1 > 5) print "yes"}')
if [ "$LARGE_CHANGE" = "yes" ]; then
    if grep -Ei "$PERF_KEYWORDS" "$PATCH_FILE"; then
        check_warning "Performance Impact" 0 ""
    else
        check_warning "Performance Impact" 1 "Large changes should include performance impact assessment"
    fi
fi

echo ""
echo "=== Recipient Checks ==="

# 21. Check if get_maintainer.pl was likely used
if [ -f "$KERNEL_DIR/scripts/get_maintainer.pl" ]; then
    echo "Suggested recipients:"
    "$KERNEL_DIR/scripts/get_maintainer.pl" "$PATCH_FILE" 2>/dev/null | head -5 | sed 's/^/  /'
    echo -e "${YELLOW}⚠ Make sure to use get_maintainer.pl for recipient list${NC}"
else
    echo -e "${YELLOW}⚠ Cannot check recipients (get_maintainer.pl not found)${NC}"
fi

echo ""
echo "======================================"
echo "          VALIDATION SUMMARY"
echo "======================================"

if [ "$ERRORS" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
    echo -e "${GREEN}✓ PERFECT! Your patch is ready to send!${NC}"
    echo ""
    echo "Send with:"
    echo "  git send-email --to=<maintainer> --cc=<list> $PATCH_FILE"
    exit 0
elif [ "$ERRORS" -eq 0 ]; then
    echo -e "${YELLOW}⚠ WARNINGS: $WARNINGS issues found (patch is sendable but could be improved)${NC}"
    exit 0
else
    echo -e "${RED}✗ ERRORS: $ERRORS critical issues found${NC}"
    echo -e "${YELLOW}⚠ WARNINGS: $WARNINGS minor issues found${NC}"
    echo ""
    echo "Fix the errors before sending this patch!"
    exit 1
fi