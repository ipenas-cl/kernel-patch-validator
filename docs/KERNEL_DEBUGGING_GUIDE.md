# Kernel Debugging Guide (LFD103 Chapter 12)

## Essential Debug Configurations

### Basic Debug Options
```bash
# Add to .config or use menuconfig
CONFIG_DEBUG_KERNEL=y
CONFIG_DEBUG_INFO=y
CONFIG_DEBUG_FS=y
CONFIG_KALLSYMS_ALL=y
CONFIG_FRAME_POINTER=y
```

### Memory Debugging
```bash
CONFIG_DEBUG_SLAB=y
CONFIG_DEBUG_SLAB_LEAK=y
CONFIG_DEBUG_KMEMLEAK=y
CONFIG_DEBUG_PAGEALLOC=y
CONFIG_DEBUG_VM=y
CONFIG_DEBUG_VM_VMACHECKS=y
CONFIG_DEBUG_VM_PGTABLE=y
CONFIG_KASAN=y          # AddressSanitizer
CONFIG_KFENCE=y         # Kernel Electric Fence
```

### Locking and Concurrency
```bash
CONFIG_PROVE_LOCKING=y
CONFIG_DEBUG_SPINLOCK=y
CONFIG_DEBUG_MUTEXES=y
CONFIG_DEBUG_LOCK_ALLOC=y
CONFIG_DEBUG_ATOMIC_SLEEP=y
CONFIG_DEBUG_LOCKING_API_SELFTESTS=y
```

### Function Tracing
```bash
CONFIG_FUNCTION_TRACER=y
CONFIG_FUNCTION_GRAPH_TRACER=y
CONFIG_STACK_TRACER=y
CONFIG_IRQSOFF_TRACER=y
CONFIG_PREEMPT_TRACER=y
```

## Debugging Tools

### 1. printk and Dynamic Debug
```c
/* Basic printk levels */
#define KERN_EMERG    "<0>"  /* system is unusable */
#define KERN_ALERT    "<1>"  /* action must be taken immediately */
#define KERN_CRIT     "<2>"  /* critical conditions */
#define KERN_ERR      "<3>"  /* error conditions */
#define KERN_WARNING  "<4>"  /* warning conditions */
#define KERN_NOTICE   "<5>"  /* normal but significant condition */
#define KERN_INFO     "<6>"  /* informational */
#define KERN_DEBUG    "<7>"  /* debug-level messages */

/* Modern preferred approach */
#define pr_emerg(fmt, ...) printk(KERN_EMERG pr_fmt(fmt), ##__VA_ARGS__)
#define pr_alert(fmt, ...) printk(KERN_ALERT pr_fmt(fmt), ##__VA_ARGS__)
#define pr_crit(fmt, ...)  printk(KERN_CRIT pr_fmt(fmt), ##__VA_ARGS__)
#define pr_err(fmt, ...)   printk(KERN_ERR pr_fmt(fmt), ##__VA_ARGS__)
#define pr_warn(fmt, ...)  printk(KERN_WARNING pr_fmt(fmt), ##__VA_ARGS__)
#define pr_notice(fmt, ...) printk(KERN_NOTICE pr_fmt(fmt), ##__VA_ARGS__)
#define pr_info(fmt, ...)  printk(KERN_INFO pr_fmt(fmt), ##__VA_ARGS__)
#define pr_debug(fmt, ...) printk(KERN_DEBUG pr_fmt(fmt), ##__VA_ARGS__)

/* Device-specific debugging */
#define dev_emerg(dev, fmt, ...) dev_printk(KERN_EMERG, dev, fmt, ##__VA_ARGS__)
#define dev_alert(dev, fmt, ...) dev_printk(KERN_ALERT, dev, fmt, ##__VA_ARGS__)
#define dev_crit(dev, fmt, ...)  dev_printk(KERN_CRIT, dev, fmt, ##__VA_ARGS__)
#define dev_err(dev, fmt, ...)   dev_printk(KERN_ERR, dev, fmt, ##__VA_ARGS__)
#define dev_warn(dev, fmt, ...)  dev_printk(KERN_WARNING, dev, fmt, ##__VA_ARGS__)
#define dev_notice(dev, fmt, ...) dev_printk(KERN_NOTICE, dev, fmt, ##__VA_ARGS__)
#define dev_info(dev, fmt, ...)  dev_printk(KERN_INFO, dev, fmt, ##__VA_ARGS__)
#define dev_debug(dev, fmt, ...) dev_printk(KERN_DEBUG, dev, fmt, ##__VA_ARGS__)
```

### 2. Dynamic Debug
```bash
# Enable dynamic debug
echo 'module mymodule +p' > /sys/kernel/debug/dynamic_debug/control
echo 'file myfile.c +p' > /sys/kernel/debug/dynamic_debug/control
echo 'func myfunc +p' > /sys/kernel/debug/dynamic_debug/control

# Disable
echo 'module mymodule -p' > /sys/kernel/debug/dynamic_debug/control

# Add to kernel command line
dyndbg="module mymodule +p"
```

### 3. Kernel Debugging with GDB
```bash
# Compile with debug info
make menuconfig  # Enable CONFIG_DEBUG_INFO
make -j$(nproc)

# Using QEMU + GDB
qemu-system-x86_64 -kernel bzImage -initrd initramfs.cpio.gz -s -S
gdb vmlinux
(gdb) target remote :1234
(gdb) continue
```

### 4. KGDB (Kernel GDB)
```bash
# Kernel config
CONFIG_KGDB=y
CONFIG_KGDB_SERIAL_CONSOLE=y

# Boot with kgdb
kgdboc=ttyS0,115200 kgdbwait

# Connect from another machine
gdb vmlinux
(gdb) target remote /dev/ttyS0
(gdb) set remotebaud 115200
```

### 5. Ftrace
```bash
# Enable function tracing
echo function > /sys/kernel/debug/tracing/current_tracer

# Trace specific function
echo my_function > /sys/kernel/debug/tracing/set_ftrace_filter

# Start tracing
echo 1 > /sys/kernel/debug/tracing/tracing_on

# View trace
cat /sys/kernel/debug/tracing/trace

# Stop tracing
echo 0 > /sys/kernel/debug/tracing/tracing_on
```

### 6. Trace Events
```bash
# List available events
cat /sys/kernel/debug/tracing/available_events

# Enable specific event
echo 1 > /sys/kernel/debug/tracing/events/sched/sched_switch/enable

# Enable all events in a subsystem
echo 1 > /sys/kernel/debug/tracing/events/block/enable

# View events
cat /sys/kernel/debug/tracing/trace_pipe
```

## Kernel Panic Debugging

### Understanding Panic Messages

**Essential Reading**:
- [Debugging Analysis of Kernel panics and Kernel oopses using System Map](https://www.opensourceforu.com/2011/01/understanding-a-kernel-oops/)
- [Understanding a Kernel Oops!](https://kernelnewbies.org/KernelOops)

**What's in a Panic Message**:
```
[   42.123456] ------------[ cut here ]------------
[   42.123457] kernel BUG at mm/slab.c:1234!
[   42.123458] invalid opcode: 0000 [#1] SMP 
[   42.123459] CPU: 0 PID: 1234 Comm: test_program Not tainted 6.1.0-rc1+ #42
[   42.123460] Hardware name: QEMU Standard PC (i440FX + PIIX, 1996)
[   42.123461] RIP: 0010:kfree+0x123/0x456
[   42.123462] Code: 48 89 df e8 ... 0f 0b <0f> 0b 48 ...
[   42.123463] RSP: 0018:ffffc90000123456 EFLAGS: 00010246
[   42.123464] RAX: 0000000000000000 RBX: ffff888123456789 RCX: 0000000000000000
[   42.123465] Call Trace:
[   42.123466]  <TASK>
[   42.123467]  ? kfree+0x123/0x456
[   42.123468]  your_function+0x789/0xabc
[   42.123469]  another_function+0x12/0x34
[   42.123470]  </TASK>
[   42.123471] ---[ end trace 0123456789abcdef ]---
```

**Key Components**:
- **BUG location**: `mm/slab.c:1234` - exact file and line
- **Error type**: `invalid opcode`, `kernel BUG`, `general protection fault`
- **CPU state**: CPU number, PID, process name, taint status
- **Register dump**: RIP (instruction pointer), RSP (stack pointer), etc.
- **Call trace**: Function call sequence leading to the panic
- **Cut markers**: Use these to extract the relevant portion

### Using decode_stacktrace.sh

**Tool Location**: `scripts/decode_stacktrace.sh` in kernel source

**Basic Usage**:
```bash
# Extract panic trace between cut markers
vim panic_trace.txt
# Paste content between:
# ------------[ cut here ]------------
# ---[ end trace …. ]---

# Decode with vmlinux
./scripts/decode_stacktrace.sh ./vmlinux < panic_trace.txt

# Decode with release info
./scripts/decode_stacktrace.sh -r $(uname -r) < panic_trace.txt

# With custom paths
./scripts/decode_stacktrace.sh ./vmlinux /path/to/kernel/source /lib/modules/$(uname -r) < panic_trace.txt
```

**Advanced Usage**:
```bash
# For module crashes, provide module path
./scripts/decode_stacktrace.sh ./vmlinux . /lib/modules/$(uname -r)/kernel < panic_trace.txt

# Pipe directly from dmesg
dmesg | ./scripts/decode_stacktrace.sh ./vmlinux

# Save decoded output for analysis
./scripts/decode_stacktrace.sh ./vmlinux < panic_trace.txt > decoded_trace.txt
```

**Example Decoded Output**:
```
kfree (mm/slab.c:1234)
your_function (drivers/your_driver/main.c:567)
another_function (drivers/your_driver/init.c:123)
```

### Panic Analysis Workflow

**Step 1: Capture the Panic**
```bash
# Enable persistent logging
echo 1 > /proc/sys/kernel/printk_devkmsg

# Increase log buffer size
dmesg -n 8

# Save panic immediately
dmesg > panic_full.log
journalctl -k > panic_journal.log
```

**Step 2: Extract and Decode**
```bash
# Extract the relevant section
sed -n '/cut here/,/end trace/p' panic_full.log > panic_trace.txt

# Decode the stack trace
./scripts/decode_stacktrace.sh ./vmlinux < panic_trace.txt > decoded.txt

# Analyze the decoded trace
cat decoded.txt
```

**Step 3: Analyze the Call Path**
```bash
# Find the exact source location
grep -n "function_name" drivers/your_driver/*.c

# Check git history for recent changes
git log --oneline -10 -- drivers/your_driver/problematic_file.c

# Look for related bugs
git log --grep="similar_error" --oneline
```

**Step 4: Understand the Context**
```bash
# Check what was happening at the time
ps aux | grep process_name
lsmod | grep your_module
cat /proc/interrupts
cat /proc/meminfo
```

## Event Tracing for Advanced Debugging

### Ftrace Event System

**Available Events**:
```bash
# List all available trace events
cat /sys/kernel/debug/tracing/available_events

# Check event categories
ls /sys/kernel/debug/tracing/events/
# Output: block, ext4, irq, kmem, net, sched, skb, syscalls, etc.

# Check specific subsystem events
ls /sys/kernel/debug/tracing/events/net/
# Output: netif_receive_skb, net_dev_queue, etc.
```

**Enabling Events**:
```bash
# Enable all events (WARNING: high overhead)
cd /sys/kernel/debug/tracing/events
echo 1 > enable

# Enable specific subsystem events
echo 1 > /sys/kernel/debug/tracing/events/net/enable
echo 1 > /sys/kernel/debug/tracing/events/block/enable
echo 1 > /sys/kernel/debug/tracing/events/sched/enable

# Enable specific events
echo 1 > /sys/kernel/debug/tracing/events/net/netif_receive_skb/enable
echo 1 > /sys/kernel/debug/tracing/events/kmem/kmalloc/enable
```

**Debugging Network Issues**:
```bash
# Enable network-related events
echo 1 > /sys/kernel/debug/tracing/events/net/enable
echo 1 > /sys/kernel/debug/tracing/events/skb/enable
echo 1 > /sys/kernel/debug/tracing/events/napi/enable

# Start tracing
echo 1 > /sys/kernel/debug/tracing/tracing_on

# Reproduce the network issue
ping -c 5 google.com

# Stop tracing and examine
echo 0 > /sys/kernel/debug/tracing/tracing_on
cat /sys/kernel/debug/tracing/trace
```

**Debugging Memory Issues**:
```bash
# Enable memory allocation events
echo 1 > /sys/kernel/debug/tracing/events/kmem/enable

# Track specific allocations
echo 'call_site==your_function' > /sys/kernel/debug/tracing/events/kmem/kmalloc/filter

# Start tracing
echo 1 > /sys/kernel/debug/tracing/tracing_on

# Run your test
./your_test_program

# Analyze memory patterns
echo 0 > /sys/kernel/debug/tracing/tracing_on
cat /sys/kernel/debug/tracing/trace | grep kmalloc
```

**Debugging Scheduler Issues**:
```bash
# Enable scheduler events
echo 1 > /sys/kernel/debug/tracing/events/sched/enable

# Focus on specific process
echo 'comm=="your_process"' > /sys/kernel/debug/tracing/events/sched/sched_switch/filter

# Trace context switches
echo 1 > /sys/kernel/debug/tracing/tracing_on
# Run your workload
echo 0 > /sys/kernel/debug/tracing/tracing_on

# Analyze scheduling patterns
cat /sys/kernel/debug/tracing/trace | grep sched_switch
```

### Event Tracing Best Practices

**Performance Considerations**:
```bash
# Check trace buffer size
cat /sys/kernel/debug/tracing/buffer_size_kb

# Increase buffer for longer traces
echo 4096 > /sys/kernel/debug/tracing/buffer_size_kb

# Use per-CPU buffers efficiently
cat /sys/kernel/debug/tracing/per_cpu/cpu0/trace
```

**Filtering and Focus**:
```bash
# Filter by process ID
echo 'pid==1234' > /sys/kernel/debug/tracing/events/syscalls/filter

# Filter by function
echo 'func=="your_function"' > /sys/kernel/debug/tracing/events/your_subsystem/filter

# Clear filters
echo 0 > /sys/kernel/debug/tracing/events/syscalls/filter
```

**Timing-Sensitive Debugging Tips**:
- Avoid adding `pr_debug()` messages when debugging race conditions
- Use event tracing instead of printk for timing-sensitive issues
- Enable only relevant events to minimize overhead
- Use trace markers to correlate with external events

**Race Condition Debugging**:
```bash
# Enable lock events
echo 1 > /sys/kernel/debug/tracing/events/lock/enable

# Enable irq events for interrupt context issues
echo 1 > /sys/kernel/debug/tracing/events/irq/enable

# Trace function entry/exit for critical sections
echo your_critical_function > /sys/kernel/debug/tracing/set_ftrace_filter
echo function > /sys/kernel/debug/tracing/current_tracer
```

## Common Debugging Scenarios

### 1. Kernel Panic
```bash
# Prevent reboot on panic
echo 0 > /proc/sys/kernel/panic

# Enable more verbose panic info
echo 1 > /proc/sys/kernel/panic_on_warn

# Analyze crash dump
crash vmlinux vmcore
```

### 2. Memory Leaks
```bash
# Enable kmemleak
echo scan > /sys/kernel/debug/kmemleak
cat /sys/kernel/debug/kmemleak

# Clear previous results
echo clear > /sys/kernel/debug/kmemleak
```

### 3. Lock Issues
```bash
# Check for deadlocks
cat /proc/lockdep_stats

# Enable lockdep
echo 1 > /proc/sys/kernel/lock_stat
cat /proc/lock_stat
```

### 4. Performance Issues
```bash
# Use perf
perf record -g -a sleep 10
perf report

# Profile specific function
perf record -e cycles:k -g --call-graph=fp -a sleep 10
```

## Debugging Code Examples

### 1. Memory Allocation Debugging
```c
#include <linux/slab.h>

static void *debug_kmalloc(size_t size, gfp_t flags, const char *func, int line)
{
    void *ptr = kmalloc(size, flags);
    pr_debug("%s:%d - kmalloc(%zu) = %p\n", func, line, size, ptr);
    return ptr;
}

static void debug_kfree(void *ptr, const char *func, int line)
{
    pr_debug("%s:%d - kfree(%p)\n", func, line, ptr);
    kfree(ptr);
}

#define DEBUG_KMALLOC(size, flags) debug_kmalloc(size, flags, __func__, __LINE__)
#define DEBUG_KFREE(ptr) debug_kfree(ptr, __func__, __LINE__)
```

### 2. Function Entry/Exit Tracing
```c
#define TRACE_ENTER() pr_debug("ENTER %s\n", __func__)
#define TRACE_EXIT() pr_debug("EXIT %s\n", __func__)

static int my_function(int arg)
{
    TRACE_ENTER();
    
    if (arg < 0) {
        pr_debug("Invalid argument: %d\n", arg);
        TRACE_EXIT();
        return -EINVAL;
    }
    
    TRACE_EXIT();
    return 0;
}
```

### 3. Register Dump
```c
static void dump_registers(struct my_device *dev)
{
    pr_debug("=== Register Dump ===\n");
    pr_debug("REG_CTRL: 0x%08x\n", readl(dev->base + REG_CTRL));
    pr_debug("REG_STATUS: 0x%08x\n", readl(dev->base + REG_STATUS));
    pr_debug("REG_DATA: 0x%08x\n", readl(dev->base + REG_DATA));
    pr_debug("==================\n");
}
```

## Best Practices

### 1. Conditional Debug Code
```c
#ifdef DEBUG
#define dbg_print(fmt, ...) pr_debug(fmt, ##__VA_ARGS__)
#else
#define dbg_print(fmt, ...) do { } while (0)
#endif
```

### 2. Rate-Limited Debug
```c
#include <linux/ratelimit.h>

static DEFINE_RATELIMIT_STATE(debug_rs, HZ, 10);

if (__ratelimit(&debug_rs))
    pr_debug("High-frequency debug message\n");
```

### 3. Hex Dumps
```c
#include <linux/printk.h>

print_hex_dump(KERN_DEBUG, "data: ", DUMP_PREFIX_OFFSET,
               16, 1, data, len, true);
```

### 4. Stack Traces
```c
#include <linux/stacktrace.h>

void print_stack_trace(void)
{
    dump_stack();
}
```

## Debugging Workflow

### 1. Initial Problem Analysis
```bash
# Check kernel log
dmesg | tail -50

# Check system resources
cat /proc/meminfo
cat /proc/slabinfo
cat /proc/vmstat
```

### 2. Enable Debug Options
```bash
# For memory issues
echo 1 > /sys/kernel/debug/kmemleak
echo scan > /sys/kernel/debug/kmemleak

# For lock issues
echo 1 > /proc/sys/kernel/lock_stat
```

### 3. Reproduce Issue
```bash
# Run test case
# Monitor with debug enabled
```

### 4. Analyze Results
```bash
# Check debug output
cat /sys/kernel/debug/kmemleak
cat /proc/lock_stat
dmesg | grep -i "debug\|error\|warning"
```

## Common Debug Patterns

### 1. Null Pointer Checks
```c
if (!ptr) {
    pr_err("Null pointer in %s at line %d\n", __func__, __LINE__);
    return -EINVAL;
}
```

### 2. Range Validation
```c
if (index >= array_size) {
    pr_err("Index %d out of bounds (max %d) in %s\n", 
           index, array_size, __func__);
    return -EINVAL;
}
```

### 3. Resource Tracking
```c
static atomic_t resource_count = ATOMIC_INIT(0);

static void *allocate_resource(void)
{
    void *res = kmalloc(sizeof(*res), GFP_KERNEL);
    if (res) {
        atomic_inc(&resource_count);
        pr_debug("Allocated resource %p (count: %d)\n", 
                res, atomic_read(&resource_count));
    }
    return res;
}

static void free_resource(void *res)
{
    if (res) {
        atomic_dec(&resource_count);
        pr_debug("Freed resource %p (count: %d)\n", 
                res, atomic_read(&resource_count));
        kfree(res);
    }
}
```

Remember: Debug code should be removed or disabled in production. Use appropriate debug levels and avoid excessive debug output that could impact performance.