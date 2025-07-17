# Kernel Patch Validator Promotion Checklist

## Phase 1: Official Channels (Week 1)

### Documentation Patch
- [ ] Send patch to kernel documentation
  ```bash
  cd promotion/
  chmod +x send-documentation-patch.sh
  ./send-documentation-patch.sh
  ```
- [ ] Monitor responses on linux-doc@vger.kernel.org
- [ ] Address any feedback from Jonathan Corbet

### Mailing Lists
- [ ] Send to linux-kernel-mentees
  ```bash
  git send-email announce-mentees-list.txt
  ```
- [ ] Send to linux-staging  
  ```bash
  git send-email staging-list-announce.txt
  ```
- [ ] Monitor responses and answer questions

## Phase 2: Community Outreach (Week 1-2)

### Social Media
- [ ] Post to Reddit r/kernel
  - Copy content from reddit-post.md
  - Post during US working hours for visibility
  
- [ ] Post to Reddit r/linux (crosspost)
  
- [ ] Twitter/Mastodon
  - Tag #LinuxKernel #OpenSource
  - Short version with link

### Forums
- [ ] kernelnewbies.org forum post
- [ ] Phoronix forums (kernel development section)

## Phase 3: Direct Outreach (Week 2)

### Friendly Maintainers
- [ ] Email Greg KH (mention it helps staging contributors)
- [ ] Email Shuah Khan (kernel mentorship angle)
- [ ] Email kernel mentorship program coordinators

### Tool Integration Proposals
- [ ] Contact b4 maintainer (Konstantin Ryabitsev)
- [ ] Contact 0-day bot team (Intel)
- [ ] kernelci.org integration proposal

## Phase 4: Content Creation (Week 3-4)

### Articles
- [ ] Write LWN article submission
- [ ] Blog post with statistics
- [ ] dev.to article

### Conference Proposals  
- [ ] Linux Plumbers CFP
- [ ] FOSDEM kernel devroom
- [ ] Kernel Recipes

## Phase 5: Package Distribution (Month 2)

### Linux Distributions
- [ ] Create Debian package
- [ ] Submit to AUR (Arch)
- [ ] Fedora COPR

## Tracking Success

### Metrics to Monitor
- GitHub stars/forks
- Mailing list mentions
- Patches mentioning tool usage
- Issue reports (shows usage!)

### Response Templates

**For Questions:**
```
Thanks for your interest! 

[Answer specific question]

The tool is designed to catch mistakes based on real rejection 
feedback. Each check exists because I or others made that mistake.

Feel free to open issues or contribute at:
https://github.com/ipenas-cl/kernel-patch-validator
```

**For Feedback:**
```
Thanks for the feedback!

[Address specific point]

I'll add this to the issue tracker. Contributions are welcome
if you'd like to implement this enhancement.
```

**For Criticism:**
```
Thanks for taking the time to review the tool.

[Acknowledge valid points]

The goal is helping newcomers avoid common rejections. If you
have suggestions for improvement, I'm happy to implement them.
```

## Notes

1. **Timing**: Send emails Tuesday-Thursday, avoid Fridays/weekends
2. **Follow-up**: Wait 1 week before gentle reminder
3. **Tone**: Professional, helpful, acknowledging we're all learning
4. **Updates**: Post updates when adding major features

## Success Indicators

- [ ] Documentation patch accepted
- [ ] 100+ GitHub stars  
- [ ] Mentioned in 5+ patch submissions
- [ ] Added to distribution packages
- [ ] Positive maintainer feedback

Remember: The goal is helping the community. Stay positive and responsive!