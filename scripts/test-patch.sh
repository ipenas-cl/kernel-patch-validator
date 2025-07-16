#!/bin/bash
# Patch Testing Workflow Script
# Based on open source testing best practices

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PATCH_FILE="$1"
KERNEL_DIR="${KERNEL_DIR:-$(pwd)}"
TEST_BRANCH="test-patch-$(date +%Y%m%d-%H%M%S)"

# Check if patch file provided
if [ -z "$PATCH_FILE" ]; then
    echo -e "${RED}ERROR: No patch file provided${NC}"
    echo "Usage: $0 <patch-file> [kernel-directory]"
    echo ""
    echo "This script will:"
    echo "1. Create a test branch"
    echo "2. Apply the patch safely"
    echo "3. Run compilation tests"
    echo "4. Perform basic validation"
    echo "5. Clean up automatically"
    exit 1
fi

if [ ! -f "$PATCH_FILE" ]; then
    echo -e "${RED}ERROR: Patch file '$PATCH_FILE' not found${NC}"
    exit 1
fi

if [ ! -d "$KERNEL_DIR" ] || [ ! -d "$KERNEL_DIR/.git" ]; then
    echo -e "${RED}ERROR: '$KERNEL_DIR' is not a git repository${NC}"
    exit 1
fi

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}    PATCH TESTING WORKFLOW${NC}"
echo -e "${BLUE}======================================${NC}"
echo "Patch: $PATCH_FILE"
echo "Kernel: $KERNEL_DIR"
echo "Test branch: $TEST_BRANCH"
echo ""

cd "$KERNEL_DIR"

# Function to cleanup on exit
cleanup() {
    echo -e "\n${YELLOW}Cleaning up...${NC}"
    
    # Return to original branch
    ORIGINAL_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "detached")
    if [ "$ORIGINAL_BRANCH" != "$TEST_BRANCH" ]; then
        git checkout "$ORIGINAL_BRANCH" >/dev/null 2>&1 || git checkout main >/dev/null 2>&1 || git checkout master >/dev/null 2>&1
    fi
    
    # Delete test branch if it exists
    if git branch | grep -q "$TEST_BRANCH"; then
        git branch -D "$TEST_BRANCH" >/dev/null 2>&1
        echo -e "${GREEN}✓ Test branch cleaned up${NC}"
    fi
}

# Set up cleanup trap
trap cleanup EXIT

echo -e "${YELLOW}=== Step 1: Creating test branch ===${NC}"
CURRENT_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD)
echo "Current branch/commit: $CURRENT_BRANCH"

git checkout -b "$TEST_BRANCH" >/dev/null 2>&1
echo -e "${GREEN}✓ Created test branch: $TEST_BRANCH${NC}"

echo -e "\n${YELLOW}=== Step 2: Applying patch ===${NC}"
PATCH_PATH=$(realpath "$PATCH_FILE")

# Try git apply first (recommended)
if git apply --check "$PATCH_PATH" >/dev/null 2>&1; then
    echo "Using git apply method..."
    git apply --index "$PATCH_PATH"
    echo -e "${GREEN}✓ Patch applied successfully with git apply${NC}"
else
    echo "git apply failed, trying patch command..."
    if patch -p1 --dry-run < "$PATCH_PATH" >/dev/null 2>&1; then
        patch -p1 < "$PATCH_PATH" >/dev/null 2>&1
        # Add any new files to git
        git add . >/dev/null 2>&1
        echo -e "${GREEN}✓ Patch applied successfully with patch command${NC}"
    else
        echo -e "${RED}✗ Patch application failed${NC}"
        echo "Patch does not apply cleanly to current tree"
        exit 1
    fi
fi

# Show what changed
NEW_FILES=$(git status --porcelain | grep "^A " | wc -l)
MODIFIED_FILES=$(git status --porcelain | grep "^M " | wc -l)
echo "Files changed: $MODIFIED_FILES modified, $NEW_FILES new"

echo -e "\n${YELLOW}=== Step 3: Pre-compilation validation ===${NC}"

# Run checkpatch if available
if [ -f "scripts/checkpatch.pl" ]; then
    echo "Running checkpatch.pl..."
    if ./scripts/checkpatch.pl --strict "$PATCH_PATH" >/tmp/checkpatch-test.out 2>&1; then
        echo -e "${GREEN}✓ checkpatch.pl passed${NC}"
    else
        echo -e "${YELLOW}⚠ checkpatch.pl warnings found${NC}"
        head -n 10 /tmp/checkpatch-test.out
    fi
else
    echo -e "${YELLOW}⚠ checkpatch.pl not found, skipping${NC}"
fi

echo -e "\n${YELLOW}=== Step 4: Compilation testing ===${NC}"

# Determine what to build based on changes
MODIFIED_AREAS=$(git diff --name-only HEAD~1 | cut -d'/' -f1 | sort -u | head -5)
echo "Modified areas: $MODIFIED_AREAS"

# Check if we need allmodconfig or can do targeted build
if echo "$MODIFIED_AREAS" | grep -q "drivers\|kernel\|mm\|fs"; then
    echo "Core areas modified, running full compilation test..."
    BUILD_TARGET="allmodconfig"
else
    echo "Limited scope changes detected..."
    BUILD_TARGET="defconfig"
fi

# Build test
echo "Building with $BUILD_TARGET..."
if make "$BUILD_TARGET" >/tmp/config.out 2>&1; then
    echo -e "${GREEN}✓ Configuration successful${NC}"
else
    echo -e "${RED}✗ Configuration failed${NC}"
    tail -n 10 /tmp/config.out
    exit 1
fi

# Compilation with timing
echo "Compiling kernel (this may take a while)..."
START_TIME=$(date +%s)

if make -j$(nproc) >/tmp/build.out 2>&1; then
    END_TIME=$(date +%s)
    BUILD_TIME=$((END_TIME - START_TIME))
    echo -e "${GREEN}✓ Compilation successful${NC} (${BUILD_TIME}s)"
else
    echo -e "${RED}✗ Compilation failed${NC}"
    echo "Build errors:"
    tail -n 20 /tmp/build.out
    exit 1
fi

echo -e "\n${YELLOW}=== Step 5: Static analysis ===${NC}"

# Run sparse if available
if command -v sparse >/dev/null 2>&1; then
    echo "Running sparse analysis..."
    MODIFIED_C_FILES=$(git diff --name-only HEAD~1 | grep '\.c$' | head -5)
    if [ -n "$MODIFIED_C_FILES" ]; then
        for file in $MODIFIED_C_FILES; do
            if [ -f "$file" ]; then
                OBJFILE=$(echo "$file" | sed 's/\.c$/.o/')
                if make C=1 "$OBJFILE" >/tmp/sparse.out 2>&1; then
                    if [ -s /tmp/sparse.out ]; then
                        echo -e "${YELLOW}⚠ Sparse warnings in $file${NC}"
                        head -n 5 /tmp/sparse.out
                    fi
                else
                    echo -e "${YELLOW}⚠ Could not run sparse on $file${NC}"
                fi
            fi
        done
        echo -e "${GREEN}✓ Sparse analysis completed${NC}"
    else
        echo "No C files modified, skipping sparse"
    fi
else
    echo -e "${YELLOW}⚠ Sparse not available, skipping${NC}"
fi

echo -e "\n${YELLOW}=== Step 6: Module testing (if applicable) ===${NC}"

# Check if patch affects modules
MODIFIED_MODULES=$(git diff --name-only HEAD~1 | grep -E 'drivers/.*\.c$|fs/.*\.c$' | head -3)
if [ -n "$MODIFIED_MODULES" ]; then
    echo "Testing module compilation..."
    if make modules >/tmp/modules.out 2>&1; then
        echo -e "${GREEN}✓ Module compilation successful${NC}"
        
        # Try to identify loadable modules
        for file in $MODIFIED_MODULES; do
            MODULE_DIR=$(dirname "$file")
            if [ -f "$MODULE_DIR/Makefile" ]; then
                echo "Modified module area: $MODULE_DIR"
            fi
        done
    else
        echo -e "${RED}✗ Module compilation failed${NC}"
        tail -n 10 /tmp/modules.out
    fi
else
    echo "No module files modified, skipping module test"
fi

echo -e "\n${YELLOW}=== Step 7: Change analysis ===${NC}"

# Analyze the changes
echo "Patch statistics:"
git diff --stat HEAD~1

echo -e "\nChange summary:"
git diff --shortstat HEAD~1

# Look for potential issues
echo -e "\nPotential concerns to verify:"
if git diff HEAD~1 | grep -q "kmalloc\|kzalloc\|vmalloc"; then
    echo -e "${YELLOW}- Memory allocation changes detected - verify error handling${NC}"
fi

if git diff HEAD~1 | grep -q "spin_lock\|mutex_lock"; then
    echo -e "${YELLOW}- Locking changes detected - verify lock ordering${NC}"
fi

if git diff HEAD~1 | grep -q "request_irq\|free_irq"; then
    echo -e "${YELLOW}- Interrupt handling changes - verify cleanup paths${NC}"
fi

echo -e "\n${GREEN}=== TESTING COMPLETE ===${NC}"
echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}         SUMMARY${NC}"
echo -e "${BLUE}======================================${NC}"
echo -e "${GREEN}✓ Patch applied successfully${NC}"
echo -e "${GREEN}✓ Compilation passed${NC}"
echo -e "${GREEN}✓ Basic validation completed${NC}"
echo ""
echo -e "${YELLOW}NEXT STEPS:${NC}"
echo "1. Install and boot test the kernel"
echo "2. Run functional tests for affected subsystems"
echo "3. Monitor dmesg for warnings/errors"
echo "4. Consider stress testing if performance-critical"
echo ""
echo -e "${YELLOW}Build artifacts saved in:${NC}"
echo "- Configuration: /tmp/config.out"
echo "- Build log: /tmp/build.out"
echo "- Module log: /tmp/modules.out" 
echo "- Checkpatch: /tmp/checkpatch-test.out"
echo ""
echo -e "${BLUE}Test branch '$TEST_BRANCH' will be cleaned up on exit${NC}"