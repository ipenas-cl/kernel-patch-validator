#!/bin/bash
# Automated Bug Finding Script
# Find easy contribution opportunities using static analysis

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

KERNEL_DIR="${KERNEL_DIR:-$(pwd)}"
OUTPUT_DIR="bug-analysis-$(date +%Y%m%d-%H%M%S)"

# Check if we're in a kernel directory
if [ ! -f "$KERNEL_DIR/MAINTAINERS" ] || [ ! -d "$KERNEL_DIR/.git" ]; then
    echo -e "${RED}ERROR: Not in a kernel git repository${NC}"
    echo "Run this script from the kernel source directory"
    exit 1
fi

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}    KERNEL BUG FINDER v1.0${NC}"
echo -e "${BLUE}======================================${NC}"
echo "Kernel: $KERNEL_DIR"
echo "Output: $OUTPUT_DIR"
echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR"
cd "$KERNEL_DIR"

echo -e "${YELLOW}=== 1. Spelling and Grammar Errors ===${NC}"
echo "Searching for common typos..."

# Common spelling mistakes
TYPOS="teh\|hte\|adn\|nad\|recieve\|occured\|seperate\|definately\|occurance\|priviledge"

if grep -r "$TYPOS" . --include="*.c" --include="*.h" --include="*.rst" > "$OUTPUT_DIR/spelling-errors.txt" 2>/dev/null; then
    SPELLING_COUNT=$(wc -l < "$OUTPUT_DIR/spelling-errors.txt")
    echo -e "${GREEN}✓ Found $SPELLING_COUNT potential spelling errors${NC}"
    echo "Top 10 spelling issues:"
    head -10 "$OUTPUT_DIR/spelling-errors.txt" | sed 's/^/  /'
else
    echo -e "${YELLOW}⚠ No spelling errors found${NC}"
fi

echo ""
echo -e "${YELLOW}=== 2. Static Analysis with Sparse ===${NC}"
echo "Running sparse analysis (this may take a while)..."

# Run sparse on staging drivers (good entry point)
if [ -d "drivers/staging" ]; then
    echo "Analyzing staging drivers..."
    if make C=1 drivers/staging/ > "$OUTPUT_DIR/sparse-staging.txt" 2>&1; then
        SPARSE_STAGING=$(grep -c "warning\|error" "$OUTPUT_DIR/sparse-staging.txt" 2>/dev/null || echo 0)
        echo -e "${GREEN}✓ Found $SPARSE_STAGING sparse issues in staging${NC}"
    else
        echo -e "${YELLOW}⚠ Sparse analysis failed or no issues found${NC}"
    fi
fi

# Run sparse on recently modified files
echo "Analyzing recently modified files..."
RECENT_FILES=$(git diff --name-only HEAD~10 | grep -E '\.(c|h)$' | head -10)
if [ -n "$RECENT_FILES" ]; then
    for file in $RECENT_FILES; do
        if [ -f "$file" ]; then
            OBJFILE=$(echo "$file" | sed 's/\.c$/.o/')
            make C=1 "$OBJFILE" >> "$OUTPUT_DIR/sparse-recent.txt" 2>&1 || true
        fi
    done
    SPARSE_RECENT=$(grep -c "warning\|error" "$OUTPUT_DIR/sparse-recent.txt" 2>/dev/null || echo 0)
    echo -e "${GREEN}✓ Found $SPARSE_RECENT sparse issues in recent files${NC}"
fi

echo ""
echo -e "${YELLOW}=== 3. Checkpatch Analysis ===${NC}"
echo "Finding checkpatch violations..."

# Check staging drivers with checkpatch
if [ -d "drivers/staging" ] && [ -f "scripts/checkpatch.pl" ]; then
    echo "Running checkpatch on staging drivers..."
    find drivers/staging/ -name "*.c" | head -20 | while read file; do
        ./scripts/checkpatch.pl --strict -f "$file" >> "$OUTPUT_DIR/checkpatch-staging.txt" 2>&1 || true
    done
    
    if [ -f "$OUTPUT_DIR/checkpatch-staging.txt" ]; then
        CHECKPATCH_COUNT=$(grep -c "ERROR\|WARNING" "$OUTPUT_DIR/checkpatch-staging.txt" 2>/dev/null || echo 0)
        echo -e "${GREEN}✓ Found $CHECKPATCH_COUNT checkpatch issues in staging${NC}"
        
        # Show top issues
        echo "Most common checkpatch issues:"
        grep -o "ERROR: [^:]*\|WARNING: [^:]*" "$OUTPUT_DIR/checkpatch-staging.txt" | \
        sort | uniq -c | sort -nr | head -5 | sed 's/^/  /'
    fi
fi

echo ""
echo -e "${YELLOW}=== 4. .gitignore Opportunities ===${NC}"
echo "Looking for missing .gitignore entries..."

# Build tools and check for untracked files
echo "Building tools to find untracked binaries..."
if make -C tools/ > "$OUTPUT_DIR/tools-build.log" 2>&1; then
    UNTRACKED_TOOLS=$(git status --porcelain tools/ | grep "^??" | wc -l)
    if [ "$UNTRACKED_TOOLS" -gt 0 ]; then
        echo -e "${GREEN}✓ Found $UNTRACKED_TOOLS untracked files in tools/${NC}"
        git status --porcelain tools/ | grep "^??" > "$OUTPUT_DIR/untracked-tools.txt"
        echo "Sample untracked files:"
        head -5 "$OUTPUT_DIR/untracked-tools.txt" | sed 's/^/  /'
    else
        echo -e "${YELLOW}⚠ No untracked files in tools/${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Tools build failed${NC}"
fi

# Check selftests
echo "Building selftests..."
if make -C tools/testing/selftests/ > "$OUTPUT_DIR/selftests-build.log" 2>&1; then
    UNTRACKED_TESTS=$(git status --porcelain tools/testing/selftests/ | grep "^??" | wc -l)
    if [ "$UNTRACKED_TESTS" -gt 0 ]; then
        echo -e "${GREEN}✓ Found $UNTRACKED_TESTS untracked files in selftests${NC}"
        git status --porcelain tools/testing/selftests/ | grep "^??" > "$OUTPUT_DIR/untracked-selftests.txt"
    else
        echo -e "${YELLOW}⚠ No untracked files in selftests${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Selftests build failed${NC}"
fi

echo ""
echo -e "${YELLOW}=== 5. Syzbot Bug Reports ===${NC}"
echo "Checking for recent syzbot reports..."

# Create a simple script to check syzbot
cat > "$OUTPUT_DIR/check-syzbot.sh" << 'EOF'
#!/bin/bash
echo "Recent syzbot reports with reproducers:"
echo "Visit: https://syzkaller.appspot.com/"
echo ""
echo "Look for reports with:"
echo "- 'C reproducer' available"
echo "- Recent timestamp (last 30 days)"
echo "- Subsystems you're interested in"
echo ""
echo "Common beginner-friendly categories:"
echo "- null pointer dereference"
echo "- WARN_ON() violations"
echo "- use-after-free (with KASAN)"
echo "- memory leaks"
EOF

chmod +x "$OUTPUT_DIR/check-syzbot.sh"
echo -e "${GREEN}✓ Created syzbot checking script${NC}"

echo ""
echo -e "${YELLOW}=== 6. Debug Configuration Issues ===${NC}"
echo "Looking for missing debug configurations..."

# Check if debug options are enabled
DEBUG_CONFIGS=("CONFIG_KASAN" "CONFIG_UBSAN" "CONFIG_LOCKDEP" "CONFIG_DEBUG_KERNEL")
MISSING_CONFIGS=""

for config in "${DEBUG_CONFIGS[@]}"; do
    if ! grep -q "^$config=y" .config 2>/dev/null; then
        MISSING_CONFIGS="$MISSING_CONFIGS $config"
    fi
done

if [ -n "$MISSING_CONFIGS" ]; then
    echo -e "${GREEN}✓ Found missing debug configurations${NC}"
    echo "Missing debug configs: $MISSING_CONFIGS" > "$OUTPUT_DIR/missing-debug-configs.txt"
    echo "Suggested debug configs to enable:"
    echo "$MISSING_CONFIGS" | tr ' ' '\n' | sed 's/^/  /'
    
    # Create enable script
    cat > "$OUTPUT_DIR/enable-debug-configs.sh" << EOF
#!/bin/bash
echo "Enabling debug configurations..."
EOF
    
    for config in $MISSING_CONFIGS; do
        echo "./scripts/config --enable $config" >> "$OUTPUT_DIR/enable-debug-configs.sh"
    done
    
    echo "make olddefconfig" >> "$OUTPUT_DIR/enable-debug-configs.sh"
    chmod +x "$OUTPUT_DIR/enable-debug-configs.sh"
    
    echo -e "${BLUE}Run $OUTPUT_DIR/enable-debug-configs.sh to enable debug options${NC}"
else
    echo -e "${YELLOW}⚠ All debug configurations already enabled${NC}"
fi

echo ""
echo -e "${GREEN}=== ANALYSIS COMPLETE ===${NC}"
echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}         SUMMARY REPORT${NC}"
echo -e "${BLUE}======================================${NC}"

# Generate summary
cat > "$OUTPUT_DIR/SUMMARY.md" << EOF
# Bug Finding Analysis Report

Generated: $(date)
Kernel: $(git describe --always)

## Findings Summary

EOF

if [ -f "$OUTPUT_DIR/spelling-errors.txt" ]; then
    SPELL_COUNT=$(wc -l < "$OUTPUT_DIR/spelling-errors.txt")
    echo "- **Spelling Errors**: $SPELL_COUNT found" >> "$OUTPUT_DIR/SUMMARY.md"
fi

if [ -f "$OUTPUT_DIR/sparse-staging.txt" ]; then
    SPARSE_COUNT=$(grep -c "warning\|error" "$OUTPUT_DIR/sparse-staging.txt" 2>/dev/null || echo 0)
    echo "- **Sparse Issues**: $SPARSE_COUNT found" >> "$OUTPUT_DIR/SUMMARY.md"
fi

if [ -f "$OUTPUT_DIR/checkpatch-staging.txt" ]; then
    CHECK_COUNT=$(grep -c "ERROR\|WARNING" "$OUTPUT_DIR/checkpatch-staging.txt" 2>/dev/null || echo 0)
    echo "- **Checkpatch Issues**: $CHECK_COUNT found" >> "$OUTPUT_DIR/SUMMARY.md"
fi

if [ -f "$OUTPUT_DIR/untracked-tools.txt" ]; then
    UNTRACK_COUNT=$(wc -l < "$OUTPUT_DIR/untracked-tools.txt")
    echo "- **Missing .gitignore**: $UNTRACK_COUNT files" >> "$OUTPUT_DIR/SUMMARY.md"
fi

cat >> "$OUTPUT_DIR/SUMMARY.md" << EOF

## Recommended Actions

1. **Easy First Contributions**:
   - Fix spelling errors (very low risk)
   - Add missing .gitignore entries
   - Fix obvious checkpatch warnings

2. **Intermediate Contributions**:
   - Fix sparse warnings in staging drivers
   - Address checkpatch errors
   - Enable debug configs and test

3. **Advanced Contributions**:
   - Investigate syzbot reports
   - Fix complex static analysis issues
   - Add new debug/testing features

## Files Generated

EOF

# List all generated files
for file in "$OUTPUT_DIR"/*; do
    if [ -f "$file" ]; then
        echo "- $(basename "$file")" >> "$OUTPUT_DIR/SUMMARY.md"
    fi
done

echo ""
echo "Analysis results saved in: $OUTPUT_DIR/"
echo ""
echo -e "${YELLOW}SUGGESTED NEXT STEPS:${NC}"
echo "1. Review the summary: cat $OUTPUT_DIR/SUMMARY.md"
echo "2. Start with spelling errors: grep -n typo $OUTPUT_DIR/spelling-errors.txt"
echo "3. Pick simple checkpatch fixes: less $OUTPUT_DIR/checkpatch-staging.txt"
echo "4. Enable debug configs: ./$OUTPUT_DIR/enable-debug-configs.sh"
echo "5. Check syzbot reports: ./$OUTPUT_DIR/check-syzbot.sh"
echo ""
echo -e "${GREEN}Happy bug hunting!${NC}"