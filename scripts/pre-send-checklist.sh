#!/bin/bash
# Pre-send checklist - Interactive validation before sending patches

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "======================================"
echo "    KERNEL PATCH PRE-SEND CHECKLIST"
echo "======================================"
echo ""

READY=true

# Function to ask yes/no questions
ask_yn() {
    local question="$1"
    local response
    
    echo -n "$question [y/N]: "
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}✓${NC}"
        return 0
    else
        echo -e "${RED}✗${NC}"
        READY=false
        return 1
    fi
}

echo "=== Basic Sanity Checks ==="
ask_yn "Is your system date correct (not 2025)?"
ask_yn "Did you run 'git config user.email' with correct email?"
ask_yn "Is this the correct git tree (net vs net-next, etc)?"

echo ""
echo "=== Patch Quality ==="
ask_yn "Does your patch do ONE thing only?"
ask_yn "Did you run checkpatch.pl --strict?"
ask_yn "Does the patch compile without warnings?"
ask_yn "Did you actually TEST the change?"
ask_yn "Is your commit message explaining WHY not WHAT?"

echo ""
echo "=== Format Checks ==="
ask_yn "Is the subject line lowercase after 'subsystem:'?"
ask_yn "Do you have Signed-off-by line?"
ask_yn "If v2+, is the changelog after --- marker?"
ask_yn "If fixing a bug, do you have Fixes: tag with 12+ chars?"

echo ""
echo "=== Recipients ==="
ask_yn "Did you run scripts/get_maintainer.pl?"
ask_yn "Are you sending to the RIGHT mailing list?"
ask_yn "Are you CCing relevant people (not spamming)?"

echo ""
echo "=== Timing ==="
ask_yn "If v2+, has it been 24+ hours since last version?"
ask_yn "If feature, is the merge window open?"
ask_yn "Are you being patient (not rushing)?"

echo ""
echo "=== Final Checks ==="
ask_yn "Will you use 'git send-email' (not attachments)?"
ask_yn "Is your email client configured for plain text?"
ask_yn "Have you read Documentation/process/submitting-patches.rst?"

echo ""
echo "======================================"

if [ "$READY" = true ]; then
    echo -e "${GREEN}✓ ALL CHECKS PASSED!${NC}"
    echo ""
    echo "Your patch appears ready to send. Good luck!"
    echo ""
    echo "Remember to send with:"
    echo "  git send-email --to=<maintainer> --cc=<list> <patch>"
else
    echo -e "${RED}✗ SOME CHECKS FAILED${NC}"
    echo ""
    echo "Please fix the issues before sending your patch."
    echo "Rushing leads to rejection!"
fi

echo "======================================"