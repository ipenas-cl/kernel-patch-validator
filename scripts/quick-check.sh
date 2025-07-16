#!/bin/bash
# Super quick sanity check - run this ALWAYS before git send-email

PATCH="$1"

if [ -z "$PATCH" ]; then
    echo "Usage: $0 <patch-file>"
    exit 1
fi

echo -n "Checking patch... "

# The absolute minimum checks that catch 90% of novice mistakes
ERRORS=""

# 1. Future date check
grep -q "Date:.*2025" "$PATCH" && ERRORS="${ERRORS}2025-DATE "

# 2. No Signed-off-by
grep -q "^Signed-off-by:" "$PATCH" || ERRORS="${ERRORS}NO-SOB "

# 3. Wrong subject format
grep -q "^Subject: \[PATCH.*\] [a-z]" "$PATCH" || ERRORS="${ERRORS}BAD-SUBJECT "

# 4. Missing v2 changelog
if grep -q "^Subject: \[PATCH v[0-9]" "$PATCH"; then
    if ! awk '/^---$/{f=1} f&&/^Changes in [vV][0-9]:/{found=1;exit} END{exit !found}' "$PATCH"; then
        ERRORS="${ERRORS}NO-CHANGELOG "
    fi
fi

# 5. Short SHA in Fixes
if grep -q "^Fixes: [0-9a-f]\{1,11\} " "$PATCH"; then
    ERRORS="${ERRORS}SHORT-SHA "
fi

if [ -z "$ERRORS" ]; then
    echo -e "\033[0;32mOK!\033[0m"
    exit 0
else
    echo -e "\033[0;31mFAILED!\033[0m"
    echo "Errors found: $ERRORS"
    echo ""
    echo "Run full validation for details:"
    echo "  validate-patch.sh $PATCH"
    exit 1
fi