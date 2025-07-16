#!/bin/bash
# Patch Series Validator
# Validates complete patch series including cover letter

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PATCH_DIR="${1:-.}"

if [ ! -d "$PATCH_DIR" ]; then
    echo -e "${RED}ERROR: Directory '$PATCH_DIR' not found${NC}"
    echo "Usage: $0 [directory-with-patches]"
    exit 1
fi

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}    PATCH SERIES VALIDATOR${NC}"
echo -e "${BLUE}======================================${NC}"
echo "Directory: $PATCH_DIR"
echo ""

cd "$PATCH_DIR"

# Find all patch files
PATCHES=$(ls -1 *.patch 2>/dev/null | sort -V)
PATCH_COUNT=$(echo "$PATCHES" | grep -c . || echo 0)

if [ "$PATCH_COUNT" -eq 0 ]; then
    echo -e "${RED}ERROR: No patch files found${NC}"
    exit 1
fi

echo "Found $PATCH_COUNT patch files:"
echo "$PATCHES" | sed 's/^/  /'
echo ""

# Check for series indicators (in content, not filename)
SERIES_PATCHES=""
for patch in $PATCHES; do
    if grep -q "Subject:.*\[PATCH.*[0-9]/[0-9]" "$patch" 2>/dev/null; then
        SERIES_PATCHES="$SERIES_PATCHES$patch\n"
    fi
done
SERIES_PATCHES=$(echo -e "$SERIES_PATCHES" | grep -v "^$")
if [ -z "$SERIES_PATCHES" ]; then
    echo -e "${YELLOW}⚠ No patch series detected (no X/Y numbering)${NC}"
    echo "Individual patches found - use validate-patch.sh instead"
    exit 0
fi

# Extract series information
SERIES_INFO=$(echo "$SERIES_PATCHES" | head -1 | grep -oE "[0-9]/[0-9]")
TOTAL_EXPECTED=$(echo "$SERIES_INFO" | cut -d'/' -f2)
echo -e "${BLUE}=== Series Information ===${NC}"
echo "Expected patches: $TOTAL_EXPECTED"

# Check for cover letter
COVER_LETTER=$(ls -1 *cover-letter* 2>/dev/null | head -1 || true)
if [ -n "$COVER_LETTER" ]; then
    echo -e "${GREEN}✓ Cover letter found: $COVER_LETTER${NC}"
    
    # Validate cover letter
    if grep -q "^\*\*\* SUBJECT HERE \*\*\*" "$COVER_LETTER"; then
        echo -e "${RED}✗ Cover letter has template subject${NC}"
    else
        echo -e "${GREEN}✓ Cover letter has proper subject${NC}"
    fi
    
    if grep -q "^\*\*\* BLURB HERE \*\*\*" "$COVER_LETTER"; then
        echo -e "${RED}✗ Cover letter has template content${NC}"
    else
        echo -e "${GREEN}✓ Cover letter has content${NC}"
    fi
else
    if [ "$TOTAL_EXPECTED" -gt 1 ]; then
        echo -e "${RED}✗ No cover letter found (required for series with 2+ patches)${NC}"
    fi
fi

echo ""
echo -e "${BLUE}=== Patch Numbering ===${NC}"

# Check numbering sequence
MISSING_PATCHES=""
for i in $(seq 1 "$TOTAL_EXPECTED"); do
    if ! echo "$PATCHES" | grep -q "\[PATCH.*$i/$TOTAL_EXPECTED"; then
        MISSING_PATCHES="$MISSING_PATCHES $i/$TOTAL_EXPECTED"
        echo -e "${RED}✗ Missing patch $i/$TOTAL_EXPECTED${NC}"
    else
        echo -e "${GREEN}✓ Found patch $i/$TOTAL_EXPECTED${NC}"
    fi
done

if [ -n "$MISSING_PATCHES" ]; then
    echo -e "${RED}ERROR: Incomplete series - missing patches:$MISSING_PATCHES${NC}"
fi

echo ""
echo -e "${BLUE}=== Individual Patch Validation ===${NC}"

# Validate each patch
ERROR_COUNT=0
WARNING_COUNT=0

for patch in $PATCHES; do
    if [[ "$patch" == *cover-letter* ]]; then
        continue
    fi
    
    echo -e "\n${YELLOW}Validating: $patch${NC}"
    
    # Run validator if available
    if [ -x "./scripts/validate-patch.sh" ]; then
        ./scripts/validate-patch.sh "$patch" 2>&1 | grep -E "(✓|✗|⚠)" || true
    else
        # Basic checks if validator not available
        if ! grep -q "^Signed-off-by:" "$patch"; then
            echo -e "${RED}✗ Missing Signed-off-by${NC}"
            ((ERROR_COUNT++))
        fi
        
        # Check subject format
        SUBJECT=$(grep "^Subject:" "$patch" | head -1)
        if ! echo "$SUBJECT" | grep -q "\[PATCH.*$i/$TOTAL_EXPECTED\]"; then
            echo -e "${YELLOW}⚠ Incorrect series numbering in subject${NC}"
            ((WARNING_COUNT++))
        fi
    fi
done

echo ""
echo -e "${BLUE}=== Series Consistency ===${NC}"

# Check if all patches are for same subsystem
SUBSYSTEMS=$(grep "^Subject:" $PATCHES | grep -v cover-letter | sed 's/.*\] //' | cut -d':' -f1 | sort -u)
SUBSYSTEM_COUNT=$(echo "$SUBSYSTEMS" | wc -l)

if [ "$SUBSYSTEM_COUNT" -eq 1 ]; then
    echo -e "${GREEN}✓ All patches target same subsystem: $SUBSYSTEMS${NC}"
else
    echo -e "${YELLOW}⚠ Patches target multiple subsystems:${NC}"
    echo "$SUBSYSTEMS" | sed 's/^/    /'
fi

# Check version consistency
VERSIONS=$(grep -h "^Subject:" $PATCHES | grep -oE "\[PATCH v[0-9]+" | sort -u)
VERSION_COUNT=$(echo "$VERSIONS" | grep -c . || echo 0)

if [ "$VERSION_COUNT" -gt 1 ]; then
    echo -e "${RED}✗ Inconsistent versions in series:${NC}"
    echo "$VERSIONS" | sed 's/^/    /'
elif [ "$VERSION_COUNT" -eq 1 ]; then
    VERSION=$(echo "$VERSIONS" | sed 's/\[PATCH //')
    echo -e "${GREEN}✓ Consistent version: $VERSION${NC}"
fi

echo ""
echo -e "${BLUE}=== Apply Test ===${NC}"

# Test if patches apply in order
if command -v git >/dev/null 2>&1 && [ -d ".git" ]; then
    echo "Testing if patches apply in order..."
    
    # Create test branch
    TEST_BRANCH="test-series-$(date +%s)"
    git checkout -b "$TEST_BRANCH" >/dev/null 2>&1
    
    APPLY_SUCCESS=true
    for i in $(seq 1 "$TOTAL_EXPECTED"); do
        PATCH_FILE=$(echo "$PATCHES" | grep "\[PATCH.*$i/$TOTAL_EXPECTED" | head -1)
        if [ -n "$PATCH_FILE" ]; then
            if git apply --check "$PATCH_FILE" >/dev/null 2>&1; then
                git apply "$PATCH_FILE" >/dev/null 2>&1
                echo -e "${GREEN}✓ Patch $i/$TOTAL_EXPECTED applies cleanly${NC}"
            else
                echo -e "${RED}✗ Patch $i/$TOTAL_EXPECTED does not apply${NC}"
                APPLY_SUCCESS=false
                break
            fi
        fi
    done
    
    # Cleanup
    git checkout - >/dev/null 2>&1
    git branch -D "$TEST_BRANCH" >/dev/null 2>&1
    
    if [ "$APPLY_SUCCESS" = true ]; then
        echo -e "${GREEN}✓ All patches apply in order${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Cannot test patch application (not in git repo)${NC}"
fi

echo ""
echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}         SUMMARY${NC}"
echo -e "${BLUE}======================================${NC}"

if [ -z "$MISSING_PATCHES" ] && [ "$ERROR_COUNT" -eq 0 ]; then
    echo -e "${GREEN}✓ Series appears complete and valid${NC}"
    echo ""
    echo "Ready to send with:"
    echo "  git send-email *.patch"
else
    echo -e "${RED}✗ Series has issues that need fixing${NC}"
    if [ -n "$MISSING_PATCHES" ]; then
        echo -e "${RED}  - Missing patches:$MISSING_PATCHES${NC}"
    fi
    if [ "$ERROR_COUNT" -gt 0 ]; then
        echo -e "${RED}  - $ERROR_COUNT errors in individual patches${NC}"
    fi
fi

if [ "$WARNING_COUNT" -gt 0 ]; then
    echo -e "${YELLOW}⚠ $WARNING_COUNT warnings to review${NC}"
fi