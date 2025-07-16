# Systematic Debugging Workflow for Kernel Development

*Based on LKMP mentee experiences and debugging best practices*

## The LKMP Debugging Framework

### Phase 1: Problem Identification and Documentation

#### Step 1: Capture the Problem
```bash
# Document everything immediately
mkdir debug-session-$(date +%Y%m%d-%H%M)
cd debug-session-$(date +%Y%m%d-%H%M)

# Capture system state
uname -a > system-info.txt
dmesg > dmesg-before.txt
lsmod > modules-before.txt
cat /proc/meminfo > meminfo-before.txt

# Document the problem
cat > problem-description.txt << 'EOF'
Problem: [What exactly is broken?]
Symptoms: [What do you observe?]
Trigger: [How to reproduce?]
Impact: [What fails/crashes?]
Environment: [Hardware, kernel version, config]
Timeline: [When did it start happening?]
EOF
```

#### Step 2: Create a Reproduction Case
```bash
# Minimal reproduction script
cat > reproduce-bug.sh << 'EOF'
#!/bin/bash
# Steps to reproduce the bug

# 1. Load module
sudo insmod your_driver.ko

# 2. Trigger the condition
echo "test" > /sys/class/your_driver/trigger

# 3. Observe the failure
dmesg | tail -20

# 4. Clean up
sudo rmmod your_driver
EOF

chmod +x reproduce-bug.sh
```

### Phase 2: Initial Investigation

#### Step 3: Gather Debug Information
```bash
# Enable debug output
echo 'file drivers/your-driver.c +p' > /sys/kernel/debug/dynamic_debug/control
echo 'module your_module +p' > /sys/kernel/debug/dynamic_debug/control

# Run with debug kernel
if ! grep -q "CONFIG_DEBUG_KERNEL=y" /boot/config-$(uname -r); then
    echo "WARNING: Debug kernel recommended"
    echo "Rebuild with: make CONFIG_DEBUG_KERNEL=y CONFIG_DEBUG_INFO=y"
fi

# Capture detailed logs
dmesg -w > debug-dmesg.log &
DMESG_PID=$!

# Run reproduction case
./reproduce-bug.sh

# Stop logging
kill $DMESG_PID
```

#### Step 4: Code Analysis
```bash
# Study the code path
grep -n "function_name" drivers/your-driver/*.c
ctags -R drivers/your-driver/
vim -t function_name  # Jump to function definition

# Check recent changes
git log --oneline -10 drivers/your-driver/
git blame drivers/your-driver/problematic-file.c

# Look for similar patterns
grep -r "similar_function" drivers/*/
```

### Phase 3: Hypothesis Formation

#### Step 5: Generate Hypotheses
```
Based on LKMP mentee experiences, common categories:

1. MEMORY ISSUES
   - Null pointer dereference
   - Use after free
   - Memory leak
   - Buffer overflow
   - Double free

2. LOCKING ISSUES
   - Deadlock
   - Race condition
   - Missing locks
   - Lock ordering problem

3. RESOURCE MANAGEMENT
   - Missing cleanup
   - Resource leak
   - Improper initialization
   - Reference counting bug

4. API MISUSE
   - Wrong function parameters
   - Incorrect return value handling
   - Missing error checks
   - Inappropriate context (atomic vs sleeping)

5. HARDWARE INTERACTION
   - Register access issues
   - Timing problems
   - Interrupt handling bugs
   - DMA mapping errors
```

#### Step 6: Prioritize Hypotheses
```bash
# Create hypothesis document
cat > hypotheses.txt << 'EOF'
Hypothesis 1: [Most likely based on symptoms]
Evidence: [What supports this theory]
Test: [How to verify/disprove]
Priority: HIGH/MEDIUM/LOW

Hypothesis 2: [Second most likely]
Evidence: [What supports this theory]
Test: [How to verify/disprove]
Priority: HIGH/MEDIUM/LOW
EOF
```

### Phase 4: Systematic Testing

#### Step 7: Test Each Hypothesis
```bash
# For memory issues
make C=1 drivers/your-driver.o  # Sparse check
make CHECK="smatch -p=kernel" C=1 drivers/your-driver.o  # Smatch

# Enable debug options
echo 1 > /sys/kernel/debug/kmemleak
echo scan > /sys/kernel/debug/kmemleak

# For locking issues
echo 1 > /proc/sys/kernel/lock_stat
cat /proc/lockdep_stats

# For performance issues
perf record -g ./reproduce-bug.sh
perf report
```

#### Step 8: Add Debug Code
```c
// Strategic debug placement based on mentee learning

// Function entry/exit
static int your_function(struct device *dev)
{
    pr_debug("%s: ENTER with dev=%p\n", __func__, dev);
    
    if (!dev) {
        pr_err("%s: NULL device pointer!\n", __func__);
        return -EINVAL;
    }
    
    // Your code here
    
    pr_debug("%s: EXIT success\n", __func__);
    return 0;
}

// Memory allocation tracking
static void *debug_kmalloc(size_t size, gfp_t flags)
{
    void *ptr = kmalloc(size, flags);
    pr_debug("ALLOC: %p size=%zu\n", ptr, size);
    return ptr;
}

static void debug_kfree(void *ptr)
{
    pr_debug("FREE: %p\n", ptr);
    kfree(ptr);
}

// State tracking
static void debug_state_change(int old_state, int new_state)
{
    pr_debug("STATE: %d -> %d\n", old_state, new_state);
}

// Register dumps
static void dump_device_registers(struct your_device *dev)
{
    pr_debug("=== REGISTER DUMP ===\n");
    pr_debug("REG_CTRL: 0x%08x\n", readl(dev->base + REG_CTRL));
    pr_debug("REG_STATUS: 0x%08x\n", readl(dev->base + REG_STATUS));
    pr_debug("===================\n");
}
```

### Phase 5: Panic and Crash Analysis

#### Step 9: Kernel Panic Analysis
```bash
# If you have a kernel panic, start here
if dmesg | grep -q "kernel BUG\|Oops\|panic"; then
    echo "Kernel panic detected - starting crash analysis"
    
    # Save the panic immediately
    dmesg > panic-$(date +%Y%m%d-%H%M%S).log
    journalctl -k > journal-$(date +%Y%m%d-%H%M%S).log
    
    # Extract the crash trace
    dmesg | sed -n '/cut here/,/end trace/p' > crash-trace.txt
    
    # Decode the stack trace if vmlinux is available
    if [ -f vmlinux ]; then
        ./scripts/decode_stacktrace.sh ./vmlinux < crash-trace.txt > decoded-crash.txt
        echo "Decoded stack trace saved to decoded-crash.txt"
        cat decoded-crash.txt
    else
        echo "vmlinux not found - install kernel-debuginfo package"
        echo "Or use: scripts/decode_stacktrace.sh -r $(uname -r) < crash-trace.txt"
    fi
    
    # Analyze the crash location
    CRASH_FUNCTION=$(grep -o '[a-zA-Z_][a-zA-Z0-9_]*+0x[0-9a-f]*/0x[0-9a-f]*' crash-trace.txt | head -1)
    echo "Primary crash location: $CRASH_FUNCTION"
    
    # Look for related source code
    if [ -n "$CRASH_FUNCTION" ]; then
        FUNC_NAME=$(echo "$CRASH_FUNCTION" | cut -d'+' -f1)
        echo "Searching for function: $FUNC_NAME"
        find . -name "*.c" -exec grep -l "$FUNC_NAME" {} \; | head -5
    fi
fi
```

#### Step 10: Advanced Debugging Techniques
```bash
# KGDB (if available)
echo ttyS0 > /sys/module/kgdboc/parameters/kgdboc
echo g > /proc/sysrq-trigger  # Enter debugger

# Ftrace
echo function > /sys/kernel/debug/tracing/current_tracer
echo your_function > /sys/kernel/debug/tracing/set_ftrace_filter
echo 1 > /sys/kernel/debug/tracing/tracing_on

# Run test
./reproduce-bug.sh

# Analyze trace
cat /sys/kernel/debug/tracing/trace

# Cleanup
echo 0 > /sys/kernel/debug/tracing/tracing_on
echo nop > /sys/kernel/debug/tracing/current_tracer
```

#### Step 11: Event Tracing for Complex Issues
```bash
# When static analysis isn't enough, use dynamic tracing

# Identify the subsystem involved
SUBSYSTEM=$(echo $DIFF_SECTIONS | grep -o '^[^/]*' | head -1)
echo "Primary subsystem: $SUBSYSTEM"

# Enable relevant event tracing
case "$SUBSYSTEM" in
    "net"|"drivers/net")
        echo "Enabling network event tracing..."
        echo 1 > /sys/kernel/debug/tracing/events/net/enable
        echo 1 > /sys/kernel/debug/tracing/events/skb/enable
        echo 1 > /sys/kernel/debug/tracing/events/napi/enable
        ;;
    "mm"|"kernel")
        echo "Enabling memory management tracing..."
        echo 1 > /sys/kernel/debug/tracing/events/kmem/enable
        echo 1 > /sys/kernel/debug/tracing/events/vmscan/enable
        ;;
    "fs"|"drivers/block")
        echo "Enabling filesystem/block tracing..."
        echo 1 > /sys/kernel/debug/tracing/events/block/enable
        echo 1 > /sys/kernel/debug/tracing/events/ext4/enable
        ;;
    "drivers")
        echo "Enabling driver event tracing..."
        echo 1 > /sys/kernel/debug/tracing/events/irq/enable
        echo 1 > /sys/kernel/debug/tracing/events/gpio/enable
        ;;
    *)
        echo "Enabling general system tracing..."
        echo 1 > /sys/kernel/debug/tracing/events/sched/enable
        ;;
esac

# Set up tracing buffer
echo 8192 > /sys/kernel/debug/tracing/buffer_size_kb

# Start tracing
echo 1 > /sys/kernel/debug/tracing/tracing_on

# Reproduce the issue
echo "Run your reproduction case now..."
echo "Press enter when done..."
read

# Stop tracing and analyze
echo 0 > /sys/kernel/debug/tracing/tracing_on

# Save trace data
cp /sys/kernel/debug/tracing/trace trace-$(date +%Y%m%d-%H%M%S).log

# Analyze trace for patterns
echo "=== Trace Analysis ==="
echo "Total events captured:"
wc -l /sys/kernel/debug/tracing/trace

echo "Most frequent events:"
grep -v '^#' /sys/kernel/debug/tracing/trace | \
awk '{print $5}' | sort | uniq -c | sort -nr | head -10

echo "Error patterns:"
grep -i "error\|fail\|warn" /sys/kernel/debug/tracing/trace | head -5

# Clean up
echo > /sys/kernel/debug/tracing/trace
echo 0 > /sys/kernel/debug/tracing/events/enable
```

#### Step 12: Binary Search for Regressions
```bash
# If it's a regression, use git bisect
git bisect start
git bisect bad HEAD  # Current broken state
git bisect good v6.0  # Last known good version

# Git will checkout a commit to test
make -j$(nproc)
./reproduce-bug.sh

# Tell git the result
git bisect bad   # If bug is present
git bisect good  # If bug is not present

# Continue until found
git bisect reset  # When done
```

### Phase 6: Root Cause Analysis

#### Step 13: Understand the Root Cause
```bash
# Document findings
cat > root-cause-analysis.txt << 'EOF'
ROOT CAUSE ANALYSIS

Problem: [Original problem statement]

Root Cause: [Fundamental reason for the bug]

Code Path: [Exact sequence of function calls leading to bug]
1. function_a() calls function_b()
2. function_b() doesn't check for NULL
3. Crash occurs when dereferencing NULL pointer

Contributing Factors:
- [Factor 1: Missing input validation]
- [Factor 2: Race condition in cleanup]
- [Factor 3: Improper error handling]

Why it wasn't caught earlier:
- [Testing gap or review oversight]

Impact Assessment:
- [Who is affected and how severely]
EOF
```

### Phase 7: Fix Development and Testing

#### Step 14: Develop the Fix
```c
// Example fix based on common mentee patterns

// BEFORE (buggy code)
static int buggy_function(struct device *dev)
{
    struct priv_data *priv = dev->driver_data;  // No NULL check
    return priv->value;  // Crash if priv is NULL
}

// AFTER (fixed code)
static int fixed_function(struct device *dev)
{
    struct priv_data *priv;
    
    if (!dev) {
        pr_err("%s: NULL device\n", __func__);
        return -EINVAL;
    }
    
    priv = dev->driver_data;
    if (!priv) {
        pr_err("%s: No private data\n", __func__);
        return -ENODATA;
    }
    
    return priv->value;
}
```

#### Step 15: Comprehensive Testing
```bash
# Test the fix
cat > test-fix.sh << 'EOF'
#!/bin/bash

echo "Testing fix..."

# Test normal operation
echo "1. Normal operation test"
./reproduce-bug.sh
if [ $? -eq 0 ]; then
    echo "PASS: Normal operation works"
else
    echo "FAIL: Normal operation broken"
fi

# Test edge cases
echo "2. Edge case testing"
# Add specific edge case tests here

# Stress testing
echo "3. Stress testing"
for i in {1..100}; do
    ./reproduce-bug.sh >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "FAIL: Iteration $i failed"
        break
    fi
done

echo "Testing complete"
EOF

chmod +x test-fix.sh
./test-fix.sh
```

### Phase 8: Documentation and Learning

#### Step 16: Document the Learning
```bash
cat > debugging-session-summary.txt << 'EOF'
DEBUGGING SESSION SUMMARY

Date: $(date)
Problem: [Brief description]
Time to resolution: [X hours/days]

KEY LEARNINGS:
1. [Technical lesson learned]
2. [Process improvement identified]
3. [Tool or technique discovered]

DEBUGGING STEPS THAT WORKED:
- [Effective technique 1]
- [Effective technique 2]

DEBUGGING STEPS THAT DIDN'T WORK:
- [Dead end 1 - why it didn't help]
- [Dead end 2 - why it didn't help]

TOOLS USED:
- [Tool 1 and effectiveness rating]
- [Tool 2 and effectiveness rating]

WHAT WOULD I DO DIFFERENTLY:
- [Process improvement 1]
- [Process improvement 2]

KNOWLEDGE GAPS IDENTIFIED:
- [Topic to study more]
- [Skill to develop]

NEXT STEPS:
- [Follow-up tasks]
- [Additional testing needed]
EOF
```

## Common Debugging Patterns from LKMP Mentees

### Pattern 1: The "Works on My Machine" Bug
```bash
# When bug is environment-specific
echo "Comparing environments..."

# Check kernel config differences
diff /boot/config-working /boot/config-broken

# Check loaded modules
diff working-lsmod.txt broken-lsmod.txt

# Check hardware differences
lspci > hardware-info.txt
cat /proc/cpuinfo > cpu-info.txt
```

### Pattern 2: The "Intermittent" Bug
```bash
# For race conditions and timing issues
echo "Analyzing intermittent bug..."

# Enable lock debugging
echo 1 > /proc/sys/kernel/prove_locking

# Add artificial delays to expose races
# In code: msleep(100); between critical operations

# Stress test to increase probability
for i in {1..1000}; do
    ./reproduce-bug.sh
    sleep 0.1
done
```

### Pattern 3: The "Performance Regression"
```bash
# For performance issues
echo "Performance analysis..."

# Baseline measurement
perf stat -r 10 ./benchmark-before

# After fix measurement  
perf stat -r 10 ./benchmark-after

# Detailed profiling
perf record -g --call-graph=fp ./benchmark-after
perf report --stdio > performance-report.txt
```

## Mentorship-Specific Tips

### Working with Your Mentor
```
DO:
- Document your debugging process before meetings
- Prepare specific questions about techniques
- Share your hypothesis and testing approach
- Ask for tool recommendations
- Request code review of debug patches

DON'T:
- Debug for days without checking in
- Hide failed attempts or dead ends
- Ask "how do I debug this?" without trying first
- Expect mentors to debug for you
```

### Learning from the Community
```
When asking for help:
1. Show what you've already tried
2. Include specific error messages
3. Provide minimal reproduction case
4. Ask about debugging approaches, not just solutions
5. Share what you learned when resolved

Example good question:
"I'm debugging a race condition in the rtl8723bs driver. I've 
enabled PROVE_LOCKING and see a lockdep warning. I think the 
issue is in the cleanup path, but I'm not sure how to trace 
the exact sequence. What debugging techniques would you 
recommend for this type of locking issue?"
```

### Building Your Debugging Toolkit
```bash
# Essential debugging tools for LKMP mentees
sudo apt install sparse smatch coccinelle
sudo apt install qemu-system-x86 gdb
sudo apt install linux-tools-$(uname -r)  # perf tools

# Create debugging aliases
cat >> ~/.bashrc << 'EOF'
alias kdebug='make C=1'
alias ksmatch='make CHECK="smatch -p=kernel" C=1'
alias kperf='perf record -g --call-graph=fp'
alias ktrace='echo function > /sys/kernel/debug/tracing/current_tracer'
EOF
```

Remember: Systematic debugging is a skill that improves with practice. Each debugging session teaches you something new about the kernel, the tools, and your own problem-solving approach. Document your learning and share it with the community!