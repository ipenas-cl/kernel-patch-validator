#!/bin/bash
# Kernel Patch Validator - Never look like a novice again!
# By Ignacio Peña - July 2024

set -e

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

# 1. Check for future dates (2025 bug)
if grep -q "Date:.*2025" "$PATCH_FILE"; then
    check_error "Date Check" 1 "Patch contains future date (2025). Fix your system date!"
else
    check_error "Date Check" 0 ""
fi

# 2. Check for Signed-off-by
if ! grep -q "^Signed-off-by: .* <.*@.*>" "$PATCH_FILE"; then
    check_error "Signed-off-by" 1 "Missing Signed-off-by line"
else
    check_error "Signed-off-by" 0 ""
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
    if ! awk '/^---$/{f=1} f&&/^[Vv][0-9]:/{found=1; exit} END{exit !found}' "$PATCH_FILE"; then
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
    if grep -q "^Cc: stable@vger.kernel.org # v[0-9]" "$PATCH_FILE"; then
        check_error "Stable Tag" 0 ""
    else
        check_error "Stable Tag" 1 "Format: Cc: stable@vger.kernel.org # v5.10+"
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
fi

echo ""
echo "=== Content Checks ==="

# 9. Check for mixed changes
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

# 10. Check commit message quality
MSG_LINES=$(awk '/^Subject:/{f=1} /^---$/{f=0} f' "$PATCH_FILE" | grep -v "^Subject:\|^$\|^Signed-off-by:\|^Fixes:\|^Cc:" | wc -l)
if [ "$MSG_LINES" -lt 3 ]; then
    check_warning "Commit Message" 1 "Commit message seems too short (explain WHY not just WHAT)"
else
    check_warning "Commit Message" 0 ""
fi

# 11. Check for common novice patterns
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
echo "=== Recipient Checks ==="

# 12. Check if get_maintainer.pl was likely used
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