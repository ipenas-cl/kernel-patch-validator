#!/bin/bash
# Interactive Contribution Readiness Checklist
# Helps newcomers prepare for their first kernel contribution

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

CHECKLIST_FILE="contribution-checklist-$(date +%Y%m%d).txt"

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}  KERNEL CONTRIBUTION READINESS${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""
echo "This checklist will help you prepare for your first kernel contribution."
echo "Answer honestly - this is for your own preparation!"
echo ""

# Initialize scoring
SCORE=0
MAX_SCORE=0

# Function to ask yes/no questions
ask_question() {
    local question="$1"
    local points="$2"
    local explanation="$3"
    
    echo -e "${YELLOW}$question${NC}"
    if [ -n "$explanation" ]; then
        echo -e "${BLUE}  ($explanation)${NC}"
    fi
    
    read -p "Answer (y/n): " answer
    case "$answer" in
        [Yy]|[Yy][Ee][Ss])
            echo -e "${GREEN}✓ Good!${NC}"
            SCORE=$((SCORE + points))
            echo "✓ $question" >> "$CHECKLIST_FILE"
            ;;
        *)
            echo -e "${RED}✗ Needs attention${NC}"
            echo "✗ $question" >> "$CHECKLIST_FILE"
            ;;
    esac
    
    MAX_SCORE=$((MAX_SCORE + points))
    echo ""
}

# Function to provide guidance
provide_guidance() {
    local topic="$1"
    local commands="$2"
    
    echo -e "${YELLOW}GUIDANCE: $topic${NC}"
    echo "$commands"
    echo ""
}

# Start checklist
echo "Starting checklist... Results will be saved to $CHECKLIST_FILE"
echo "Kernel Contribution Readiness Checklist - $(date)" > "$CHECKLIST_FILE"
echo "===========================================" >> "$CHECKLIST_FILE"
echo "" >> "$CHECKLIST_FILE"

echo -e "${BLUE}=== COMMUNITY ENGAGEMENT ===${NC}"

ask_question "Have you joined #kernelnewbies IRC channel?" 2 \
    "Essential for getting help and connecting with other newcomers"

ask_question "Are you subscribed to linux-kernel-mentees mailing list?" 2 \
    "Low-volume, beginner-friendly list for questions"

ask_question "Have you read recent LKML discussions in your area of interest?" 3 \
    "Understanding community dynamics and current issues"

ask_question "Do you understand kernel community etiquette?" 3 \
    "No top-posting, proper patch format, constructive communication"

echo -e "${BLUE}=== TECHNICAL SETUP ===${NC}"

ask_question "Do you have a complete kernel development environment?" 3 \
    "GCC, git, sparse, smatch, build tools installed"

ask_question "Have you successfully built a kernel from source?" 4 \
    "Essential skill - must be able to compile and test changes"

ask_question "Can you boot and test your custom kernel?" 3 \
    "Critical for validating your changes work"

ask_question "Is your git configured for kernel development?" 2 \
    "User name, email, send-email settings configured"

ask_question "Do you understand git send-email workflow?" 4 \
    "Required for submitting patches to mailing lists"

echo -e "${BLUE}=== KERNEL KNOWLEDGE ===${NC}"

ask_question "Do you understand kernel coding style?" 3 \
    "Tabs not spaces, 80 columns, naming conventions, etc."

ask_question "Can you read and understand kernel source code?" 4 \
    "Ability to navigate and comprehend kernel code structure"

ask_question "Do you understand the patch submission process?" 4 \
    "Format, recipients, review process, iteration cycle"

ask_question "Can you use checkpatch.pl and understand its output?" 3 \
    "Essential tool for validating patch format and style"

ask_question "Do you know how to find appropriate maintainers?" 3 \
    "Using get_maintainer.pl and understanding MAINTAINERS file"

echo -e "${BLUE}=== DEBUGGING SKILLS ===${NC}"

ask_question "Can you debug compilation errors?" 3 \
    "Understanding compiler messages and fixing build issues"

ask_question "Do you know how to use kernel debugging tools?" 2 \
    "Familiarity with sparse, smatch, dynamic debugging"

ask_question "Can you reproduce and analyze bug reports?" 3 \
    "Essential for contributing meaningful fixes"

ask_question "Do you understand kernel panic/oops messages?" 2 \
    "Ability to read and interpret crash dumps"

echo -e "${BLUE}=== TESTING CAPABILITIES ===${NC}"

ask_question "Can you test your changes thoroughly?" 4 \
    "Compilation, boot testing, functional testing"

ask_question "Do you have access to test hardware/VMs?" 2 \
    "Ability to test changes in realistic environments"

ask_question "Can you create reproduction cases for bugs?" 3 \
    "Writing test programs to trigger and validate fixes"

ask_question "Do you understand regression testing?" 3 \
    "Ensuring changes don't break existing functionality"

echo -e "${BLUE}=== CONTRIBUTION READINESS ===${NC}"

ask_question "Have you identified potential first contributions?" 3 \
    "Specific areas you want to work on"

ask_question "Do you have time for iterative review process?" 3 \
    "Kernel reviews can take weeks with multiple iterations"

ask_question "Are you prepared for constructive criticism?" 4 \
    "Reviews can be direct and technically demanding"

ask_question "Do you understand 'one logical change per patch'?" 3 \
    "Fundamental principle of kernel patch organization"

# Calculate final score
echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}         CHECKLIST RESULTS${NC}"
echo -e "${BLUE}======================================${NC}"

PERCENTAGE=$((SCORE * 100 / MAX_SCORE))

echo "Final Score: $SCORE / $MAX_SCORE ($PERCENTAGE%)" | tee -a "$CHECKLIST_FILE"
echo "" | tee -a "$CHECKLIST_FILE"

if [ "$PERCENTAGE" -ge 80 ]; then
    echo -e "${GREEN}🎉 EXCELLENT! You're ready to start contributing!${NC}" | tee -a "$CHECKLIST_FILE"
    echo -e "${GREEN}Suggested next steps:${NC}"
    echo "1. Pick a simple first contribution (spelling, .gitignore)"
    echo "2. Use our find-bugs.sh script to identify opportunities"
    echo "3. Join #kernelnewbies and introduce yourself"
    echo "4. Start with staging driver cleanups"
    
elif [ "$PERCENTAGE" -ge 60 ]; then
    echo -e "${YELLOW}👍 GOOD! You're almost ready, just a few areas to improve.${NC}" | tee -a "$CHECKLIST_FILE"
    echo -e "${YELLOW}Focus on these areas:${NC}"
    echo "1. Strengthen technical setup and testing capabilities"
    echo "2. Practice with kernel development tools"
    echo "3. Read more kernel code and documentation"
    echo "4. Consider starting with documentation contributions"
    
elif [ "$PERCENTAGE" -ge 40 ]; then
    echo -e "${YELLOW}📚 DEVELOPING! You need more preparation before contributing.${NC}" | tee -a "$CHECKLIST_FILE"
    echo -e "${YELLOW}Recommended preparation:${NC}"
    echo "1. Complete LFD103 course"
    echo "2. Set up proper development environment"
    echo "3. Practice building and testing kernels"
    echo "4. Join community channels and observe discussions"
    
else
    echo -e "${RED}🎯 GETTING STARTED! You need significant preparation.${NC}" | tee -a "$CHECKLIST_FILE"
    echo -e "${RED}Start with these fundamentals:${NC}"
    echo "1. Learn C programming and Linux basics"
    echo "2. Complete kernel development course (LFD103)"
    echo "3. Set up development environment"
    echo "4. Practice with simpler open source projects first"
fi

echo "" | tee -a "$CHECKLIST_FILE"

# Provide specific guidance based on gaps
echo -e "${BLUE}=== SPECIFIC GUIDANCE ===${NC}" | tee -a "$CHECKLIST_FILE"

if ! grep -q "✓.*IRC" "$CHECKLIST_FILE"; then
    provide_guidance "JOIN IRC CHANNELS" \
"# Connect to IRC
IRC client: irc.oftc.net
Join: #kernelnewbies
Introduce yourself and ask questions!"
fi

if ! grep -q "✓.*development environment" "$CHECKLIST_FILE"; then
    provide_guidance "SET UP DEVELOPMENT ENVIRONMENT" \
"# Install essential tools
sudo apt install build-essential git sparse smatch coccinelle
sudo apt install linux-headers-\$(uname -r) libssl-dev libelf-dev

# Clone kernel source
git clone https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git"
fi

if ! grep -q "✓.*built a kernel" "$CHECKLIST_FILE"; then
    provide_guidance "BUILD YOUR FIRST KERNEL" \
"# Build kernel
cd linux
make defconfig
make -j\$(nproc)

# Enable debug options
./scripts/config --enable CONFIG_DEBUG_KERNEL
make olddefconfig && make -j\$(nproc)"
fi

if ! grep -q "✓.*git.*email" "$CHECKLIST_FILE"; then
    provide_guidance "CONFIGURE GIT FOR KERNEL DEVELOPMENT" \
"# Configure git
git config user.name \"Your Name\"
git config user.email \"your.email@example.com\"
git config sendemail.smtpserver smtp.gmail.com
git config sendemail.smtpencryption tls
git config sendemail.confirm auto"
fi

if ! grep -q "✓.*mailing list" "$CHECKLIST_FILE"; then
    provide_guidance "SUBSCRIBE TO MAILING LISTS" \
"# Subscribe to beginner-friendly lists
echo \"subscribe linux-kernel-mentees\" | mail majordomo@lists.linuxfoundation.org

# For specific subsystems:
echo \"subscribe netdev\" | mail majordomo@vger.kernel.org  # networking
echo \"subscribe linux-mm\" | mail majordome@kvack.org     # memory management"
fi

# Create action plan
echo -e "${BLUE}=== YOUR ACTION PLAN ===${NC}" | tee -a "$CHECKLIST_FILE"
echo "" | tee -a "$CHECKLIST_FILE"

if [ "$PERCENTAGE" -ge 80 ]; then
    cat >> "$CHECKLIST_FILE" << EOF
WEEK 1:
- Use find-bugs.sh to identify first contribution
- Fix spelling errors or add .gitignore entries
- Submit first patch for review

WEEK 2-3:
- Address review feedback
- Start work on second contribution
- Help other newcomers on IRC

MONTH 2:
- Pick a subsystem to specialize in
- Fix more complex issues (checkpatch, sparse warnings)
- Participate in mailing list discussions
EOF

elif [ "$PERCENTAGE" -ge 60 ]; then
    cat >> "$CHECKLIST_FILE" << EOF
WEEK 1-2:
- Complete technical setup (missing tools/configs)
- Practice building and testing kernels
- Join community channels

WEEK 3-4:
- Study kernel code in area of interest
- Practice using development tools
- Complete LFD103 course if not done

MONTH 2:
- Attempt first simple contribution
- Focus on documentation or obvious fixes
EOF

else
    cat >> "$CHECKLIST_FILE" << EOF
MONTH 1:
- Complete C programming practice
- Set up development environment
- Join IRC and mailing lists (observe mode)

MONTH 2:
- Complete LFD103 course
- Practice building kernels
- Study kernel documentation

MONTH 3:
- Attempt first kernel build and test
- Start analyzing simple issues
- Prepare for first contribution
EOF
fi

echo "" | tee -a "$CHECKLIST_FILE"
echo "📋 Complete checklist saved to: $CHECKLIST_FILE"
echo ""

# Offer to run other tools
echo -e "${YELLOW}RELATED TOOLS AVAILABLE:${NC}"
echo "• ./scripts/find-bugs.sh - Find contribution opportunities"
echo "• ./scripts/validate-patch.sh - Validate patches before sending"
echo "• ./scripts/test-patch.sh - Test patches thoroughly"
echo ""

read -p "Would you like to run the bug finder to identify opportunities? (y/n): " run_bugs
if [[ "$run_bugs" =~ ^[Yy] ]]; then
    echo "Starting bug finder..."
    ./scripts/find-bugs.sh
fi

echo ""
echo -e "${GREEN}Good luck with your kernel contribution journey! 🚀${NC}"
echo -e "${BLUE}Remember: Everyone started as a beginner. Be patient and persistent!${NC}"