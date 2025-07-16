# Mentorship Communication Best Practices

## Communication Channels and Etiquette

### Linux Kernel Mentees Mailing List
**List**: linux-kernel-mentees@lists.linuxfoundation.org

#### Posting Guidelines
```
Subject Format:
[HELP] subsystem: specific question about X
[UPDATE] mentorship week N: progress report
[PATCH RFC] subsystem: description for feedback

Good Examples:
✓ [HELP] staging: understanding device tree bindings
✓ [UPDATE] week 8: network driver debugging progress  
✓ [PATCH RFC] input: add support for new touchpad

Bad Examples:
✗ Help needed
✗ My patch doesn't work
✗ Question about kernel
```

#### Email Content Structure
```
1. Clear context - what you're working on
2. Specific question or problem
3. What you've already tried
4. Relevant code snippets or logs
5. Your environment (arch, kernel version, etc.)

Template:
Hi everyone,

I'm working on [project description] as part of the LKMP program.

Problem: [specific issue you're facing]

I've tried:
- [approach 1 and result]
- [approach 2 and result]

Environment:
- Kernel version: 6.1-rc7
- Architecture: x86_64
- Config: allmodconfig with DEBUG_KERNEL=y

Code snippet: [relevant code]

Any guidance would be appreciated!

Thanks,
[Your name]
```

### IRC Channel: #kernel-mentees
**Server**: irc.oftc.net
**Channel**: #kernel-mentees

#### IRC Etiquette
```bash
# Join the channel
/join #kernel-mentees

# Introduce yourself when first joining
Hi everyone! I'm [name], starting LKMP focusing on [subsystem]. 
Looking forward to learning from the community.

# Ask questions effectively
Instead of: "Can someone help me?"
Use: "I'm debugging a race condition in drivers/staging/rtl8723bs. 
The issue happens during module unload. Has anyone seen similar issues?"

# Share progress
Weekly: "Made progress on fixing checkpatch warnings in staging drivers. 
Submitted 3 patches this week, one already accepted!"
```

#### Common IRC Commands
```bash
/nick your_nickname          # Set your nickname
/msg NickServ register       # Register your nickname
/query username              # Private message
/names                       # See who's in channel
/topic                       # See channel topic
```

### LFX Mentorship Forum

#### Forum Best Practices
```
1. Use appropriate tags: [kernel], [lkmp], [help], [update]
2. Search before posting to avoid duplicates
3. Include code snippets with proper formatting
4. Update posts with solutions when found
5. Help other mentees when you can
```

## Communication with Mentors

### Weekly Check-ins

#### Preparation Template
```
Week [N] Update - [Your Name]

COMPLETED THIS WEEK:
□ [Task 1] - [brief description and outcome]
□ [Task 2] - [brief description and outcome]

BLOCKERS/CHALLENGES:
□ [Blocker 1] - [what you've tried, what help you need]
□ [Blocker 2] - [specific question or guidance needed]

GOALS FOR NEXT WEEK:
□ [Goal 1] - [specific, measurable objective]
□ [Goal 2] - [specific, measurable objective]

PATCHES SUBMITTED:
□ [Patch 1] - [link to lore.kernel.org or patchwork]
□ [Patch 2] - [status: under review, accepted, needs v2]

QUESTIONS FOR MENTOR:
1. [Specific technical question]
2. [Strategic/direction question]
3. [Learning resource request]

CODE REVIEW REQUESTS:
[Attach patches or provide links to work in progress]
```

#### During Check-in Meetings
```
DO:
- Have specific questions prepared
- Share your screen to show code/issues
- Take notes during the discussion
- Ask for clarification when needed
- Discuss both technical and non-technical concerns

DON'T:
- Say "everything is fine" if you're struggling
- Wait until the meeting to think about questions
- Forget to follow up on action items
- Be afraid to admit you don't understand something
```

### Email Communication with Mentors

#### Subject Line Examples
```
✓ LKMP Week 5: Debugging race condition in rtl8723bs
✓ LKMP Update: First patch accepted, next steps?
✓ LKMP Help: Understanding memory barriers in driver code
✓ LKMP Check-in: Progress report and questions

✗ Help
✗ My code
✗ Question
✗ Update
```

#### Professional Email Template
```
Subject: LKMP Week [N]: [Specific topic]

Hi [Mentor name],

[Brief context if needed]

Progress update:
- [Accomplishment 1]
- [Accomplishment 2]

Challenge I'm facing:
[Specific technical challenge with context]

I've tried:
1. [Approach 1 and result]
2. [Approach 2 and result]

Questions:
1. [Specific question 1]
2. [Specific question 2]

Next steps I'm planning:
- [Step 1]
- [Step 2]

Please let me know if you'd like me to share any code or logs.

Best regards,
[Your name]
```

## Community Interaction Guidelines

### Mailing List Participation (LKML, subsystem lists)

#### Observing and Learning
```bash
# Subscribe to relevant lists
echo "subscribe linux-kernel-mentees" | mail majordomo@vger.kernel.org
echo "subscribe netdev" | mail majordomo@vger.kernel.org

# Read archives to understand communication patterns
https://lore.kernel.org/linux-kernel/
https://lore.kernel.org/netdev/

# Study good patch submissions
git log --grep="staging" --oneline | head -10
```

#### Your First Posts
```
Start with:
1. Documentation fixes (low controversy)
2. Simple checkpatch cleanups
3. Asking specific technical questions

Avoid initially:
1. Major feature additions
2. Architectural changes  
3. Controversial topics
4. Criticism of existing code without solutions
```

#### Responding to Feedback
```
Good Response Pattern:
> Reviewer comment or question

Your specific, technical response addressing the comment.

If you agree: "You're absolutely right. I'll fix this in v2."
If you disagree: "I chose this approach because [technical reason]. 
However, if you prefer [alternative], I can change it."
If unclear: "Could you clarify what you mean by [specific part]?"

Always end with: "Thanks for the review!"
```

### Patch Submission Communication

#### Cover Letter for Patch Series
```
Subject: [PATCH 0/3] staging: rtl8723bs: fix checkpatch warnings

This series fixes checkpatch warnings in the rtl8723bs staging driver.

The patches address:
1. Incorrect spacing around operators
2. Lines exceeding 80 characters  
3. Missing blank lines after declarations

All patches have been tested by loading/unloading the module
and verifying basic WiFi functionality still works.

[Your name] (3):
  staging: rtl8723bs: fix spacing around operators
  staging: rtl8723bs: fix long lines in core/rtw_security.c
  staging: rtl8723bs: add missing blank lines

 drivers/staging/rtl8723bs/core/rtw_security.c | 45 +++++++++------
 drivers/staging/rtl8723bs/hal/hal_intf.c      | 12 ++--
 drivers/staging/rtl8723bs/os_dep/ioctl_linux.c | 8 ++-
 3 files changed, 38 insertions(+), 27 deletions(-)
```

#### Following Up on Patches
```
Appropriate Follow-ups:

After 1 week (for non-critical):
"Hi, I wanted to follow up on this patch submitted last week. 
Please let me know if you need any additional information."

After 2 weeks (for staging):
"Gentle ping on this patch series. Is there anything I can 
do to help move this forward?"

Never appropriate:
- Daily pings
- Demands for immediate review
- Complaints about slow response
- Threats to abandon the patch
```

## Documentation and Progress Tracking

### Personal Learning Log
```
Date: [YYYY-MM-DD]
Week: [N]
Focus Area: [subsystem/topic]

What I learned:
- [Technical concept 1]
- [Technical concept 2]
- [Process learning 1]

Challenges faced:
- [Challenge 1] - [how resolved or still blocking]
- [Challenge 2] - [what help needed]

Code written:
- [Brief description of patches/contributions]
- [Links to submissions]

Community interactions:
- [Mailing list discussions participated in]
- [Help received from community]
- [Help given to others]

Next week goals:
- [Specific goal 1]
- [Specific goal 2]
```

### Blog Writing (Public Learning)

#### Good Blog Post Topics
```
✓ "My first kernel patch: lessons learned"
✓ "Debugging a race condition in staging drivers"
✓ "Understanding device tree bindings: a beginner's guide"
✓ "Setting up a kernel development environment"
✓ "Common checkpatch warnings and how to fix them"

✗ "Why the kernel is bad" (criticism without solutions)
✗ "My mentor is unhelpful" (inappropriate personal comments)
✗ "This should be easier" (complaints without contribution)
```

#### Blog Post Structure
```
1. Hook - interesting problem or discovery
2. Context - what you were working on
3. Challenge - specific technical issue faced
4. Process - how you investigated and learned
5. Solution - what worked and why
6. Lessons - what you learned that others could apply
7. Next steps - how you'll build on this learning

Include:
- Code snippets with explanation
- Links to actual patches submitted
- References to helpful resources
- Acknowledgments to mentors/reviewers
```

## Building Professional Relationships

### Networking at Virtual Events

#### Conference Participation
```
Preparation:
- Read presenter bios and talk abstracts
- Prepare thoughtful questions
- Set up professional virtual background
- Test audio/video beforehand

During talks:
- Use chat appropriately for questions
- Take notes on interesting topics
- Connect concepts to your mentorship work

Follow-up:
- Email speakers with thoughtful questions
- Reference specific points from their talks
- Share your mentorship work if relevant
```

#### Virtual Networking Events
```
Introduction Template:
"Hi, I'm [name], currently participating in the Linux Kernel 
Mentorship Program working on [specific area]. I'm particularly 
interested in [topic] and enjoyed your talk about [specific point]."

Conversation Topics:
- Your mentorship project and learning goals
- Specific technical challenges you're facing
- Ask about their experience with kernel development
- Request advice for getting more involved in their subsystem
```

### Long-term Relationship Building

#### Giving Back to Community
```
As you progress:
- Answer questions from newer mentees
- Review beginner patches when you're able
- Write helpful documentation
- Present your work at conferences
- Mentor future LKMP participants

Ways to stay connected:
- Subscribe to relevant mailing lists
- Attend kernel developer conferences
- Contribute regularly, even if small patches
- Participate in community discussions
- Share knowledge through blogs/talks
```

#### Professional Development
```
LinkedIn/Professional Profiles:
- Highlight LKMP participation
- List specific kernel contributions
- Connect with mentors and fellow mentees
- Share learning achievements and milestones

Resume Building:
- Document specific patches accepted
- Quantify impact (bugs fixed, features added)
- Highlight collaboration and code review skills
- Emphasize continuous learning and community contribution
```

Remember: The kernel community values technical competence, professionalism, and constructive contribution. Focus on learning, helping others, and making meaningful contributions rather than self-promotion.