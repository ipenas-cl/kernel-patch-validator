# Kernel Testing Guide (LFD103 Chapter 11)

## Testing Philosophy

> "If you didn't test it, it doesn't work." - Kernel Development Rule

Testing is not optional in kernel development. Every patch must be tested before submission.

## Open Source Testing Model

### Developer vs User Testing

**Key Principle**: In open source development, both developers AND users are responsible for testing. This is fundamentally different from closed development models.

**Why User Testing Matters**:
- Users test configurations developers don't have access to
- Users find interactions with different hardware combinations  
- Users discover edge cases in real-world usage patterns
- Users provide broader coverage than any single developer could achieve

**Developer Limitations**:
- Limited hardware access
- Focused on specific code paths
- May miss integration issues
- Can develop "code blindness" to their own bugs

### Continuous Integration Philosophy

The open development model requires continuous testing because:
- Multiple developers add features simultaneously
- Bug fixes can introduce regressions
- New hardware support can break existing functionality
- Integration happens continuously, not at release time

## Automated Testing Infrastructure

### Kernel CI and Build Bots

**0-day Build Bot**:
- Automatically tests patches from maintainer trees
- Covers multiple architectures (x86, ARM, RISC-V, etc.)
- Tests various configurations (allmodconfig, defconfig, tinyconfig)
- Reports build failures and warnings within hours
- Access: https://01.org/lkp/documentation/0-day-test-service

**Linux-next Integration**:
- Daily integration of subsystem trees
- Early detection of conflicts and integration issues
- Broader testing before reaching mainline
- Request inclusion: email linux-next maintainer

**Continuous Integration Rings**:
- KernelCI: https://kernelci.org/
- Linaro QA: Tests ARM/ARM64 platforms
- Intel 0-day: Build and boot testing
- Google's syzbot: Fuzzing and crash detection

### Monitoring CI Results

**Check These Dashboards Before Submitting**:
```bash
# Kernel CI Dashboard
curl -s "https://api.kernelci.org/boot" | jq '.result[] | select(.status != "PASS")'

# Check 0-day reports
# Subscribe to: 0day-ci@lists.01.org

# Monitor your subsystem
git log --oneline --since="1 week ago" drivers/your-subsystem/
```

**Understanding CI Failures**:
```
BUILD FAILURES:
- Missing dependencies
- Architecture-specific issues  
- Configuration conflicts
- Header file problems

BOOT FAILURES:
- Kernel panic during boot
- Missing essential drivers
- Device tree issues
- Memory layout problems

RUNTIME FAILURES:
- Crashes under load
- Performance regressions
- Feature malfunctions
- Resource leaks
```

## Patch Application and Testing Workflow

### Applying Patches for Testing

**Method 1: Using patch command**
```bash
# Apply the patch
patch -p1 < file.patch

# Handle new files (git doesn't track them automatically)
git status  # Shows untracked files
git add .   # Add new files to tracking
```

**Method 2: Using git apply (recommended)**
```bash
# Apply and add to index
git apply --index file.patch

# This handles new files correctly
git status  # Shows newly created files as staged
git diff    # Shows the complete patch
```

**Cleaning Up After Testing**
```bash
# If using patch command, clean untracked files first
git clean -dfx  # Remove untracked files and directories

# Then reset
git reset --hard HEAD

# If using git apply --index
git reset --hard HEAD  # This handles everything correctly
```

**Testing Multiple Patches**
```bash
# Create a testing branch
git checkout -b test-patches

# Apply patches one by one
git apply --index patch1.patch
# Test patch 1
git commit -m "Test: Apply patch 1"

git apply --index patch2.patch  
# Test patches 1+2 together
git commit -m "Test: Apply patch 2"

# When done testing
git checkout main
git branch -D test-patches
```

## Basic Functional Testing

### Post-Boot Validation

**Essential System Checks**:
```bash
# Boot the new kernel
uname -a  # Verify kernel version

# Check for critical issues
dmesg -t -l emerg   # Emergency level messages (should be none)
dmesg -t -l crit    # Critical level messages (should be none) 
dmesg -t -l alert   # Alert level messages (should be none)
dmesg -t -l err     # Error level messages (investigate any new ones)
dmesg -t -l warn    # Warning level messages (check for new ones)

# Look for stack traces
dmesg | grep -i "warn_on\|bug_on\|oops\|panic"
```

**Network Connectivity Tests**:
```bash
# Basic connectivity
ping -c 3 8.8.8.8

# WiFi functionality (if applicable)
iwconfig
nmcli dev wifi list

# SSH functionality
ssh localhost 'echo "SSH working"'

# File transfer stress test
rsync -av /usr/src/linux/ /tmp/rsync-test/
time scp large-file.iso user@remote:/tmp/
```

**Storage and Filesystem Tests**:
```bash
# Filesystem operations
dd if=/dev/zero of=/tmp/test-file bs=1M count=100
sync
rm /tmp/test-file

# USB device testing
# Insert USB stick, check dmesg
dmesg | tail -10
lsusb
mount /dev/sdb1 /mnt/usb
cp /tmp/test-data /mnt/usb/
umount /mnt/usb
```

**Application Tests**:
```bash
# Web browser test
firefox --new-instance &
# Load a few web pages, play a video

# Audio/video playback
aplay /usr/share/sounds/alsa/Front_Left.wav
mpv /path/to/test-video.mp4

# Email client
thunderbird &

# Development tools
git clone https://github.com/torvalds/linux.git /tmp/git-test
cd /tmp/git-test && git pull
```

## Stress Testing and Performance Validation

### Parallel Kernel Compilation Test

**Setup Multiple Kernel Sources**:
```bash
# Download different kernel trees
mkdir /tmp/stress-test
cd /tmp/stress-test

git clone --depth 1 https://github.com/torvalds/linux.git linux-main
git clone --depth 1 https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git linux-stable  
git clone --depth 1 https://git.kernel.org/pub/scm/linux/kernel/git/next/linux-next.git linux-next
```

**Parallel Compilation Stress Test**:
```bash
#!/bin/bash
# stress-compile.sh

CORES=$(nproc)
TEST_DIRS=("linux-main" "linux-stable" "linux-next")

echo "Starting parallel compilation on $CORES cores..."

for dir in "${TEST_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo "Starting compilation in $dir"
        (
            cd "$dir"
            make allmodconfig >/dev/null 2>&1
            time make -j$CORES >/dev/null 2>&1
        ) &
    fi
done

# Wait for all compilations to complete
wait

echo "All compilations finished"
```

**Performance Regression Detection**:
```bash
# Baseline measurement (before patch)
time make -j$(nproc) > baseline-time.txt 2>&1

# Apply your patch and rebuild
git apply --index your-patch.patch
make clean
time make -j$(nproc) > patched-time.txt 2>&1

# Compare compilation times
echo "Baseline time:"
grep real baseline-time.txt
echo "Patched time:"  
grep real patched-time.txt

# Significant increase (>5%) warrants investigation
```

## Minimum Testing Requirements

### 1. Compilation Testing
```bash
# Basic compilation (absolute minimum)
make allmodconfig
make -j$(nproc)

# Cross-compilation testing (recommended)
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- allmodconfig
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j$(nproc)

# Different compiler testing
make CC=clang -j$(nproc)
```

### 2. Static Analysis
```bash
# Sparse checking (mandatory for serious patches)
make C=1 drivers/your/driver.o
make C=2  # Check all files

# Smatch checking (highly recommended)
make CHECK="smatch -p=kernel" C=1 drivers/your/driver.o

# Coccinelle semantic patches
make coccicheck MODE=report
```

### 3. Style Validation
```bash
# checkpatch.pl (mandatory)
./scripts/checkpatch.pl --strict your.patch

# Additional style checks
./scripts/get_maintainer.pl --check-only your.patch
./scripts/spelling.txt  # Check for typos
```

## Comprehensive Testing Levels

### Level 1: Basic Testing (Minimum for any patch)
```bash
# 1. Compile test
make allmodconfig && make -j$(nproc)

# 2. Style check
./scripts/checkpatch.pl --strict patch.patch

# 3. Apply test
git apply --check patch.patch

# 4. Documentation check
make htmldocs 2>&1 | grep -i warning
```

### Level 2: Standard Testing (For non-trivial patches)
```bash
# All Level 1 tests plus:

# 1. Cross-architecture compile
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- allmodconfig
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j$(nproc)

# 2. Static analysis
make C=1 drivers/your/modified_file.o
make CHECK="smatch -p=kernel" C=1 drivers/your/modified_file.o

# 3. Module loading test (if applicable)
make modules
sudo insmod your_module.ko
sudo rmmod your_module

# 4. Basic functionality test
# Run your specific test case here
```

### Level 3: Thorough Testing (For complex patches)
```bash
# All Level 2 tests plus:

# 1. Multiple compiler testing
make CC=gcc-9 -j$(nproc)
make CC=clang -j$(nproc)

# 2. Different configurations
make defconfig && make -j$(nproc)
make tinyconfig && make -j$(nproc)

# 3. Stress testing
# Run your stress tests here

# 4. Performance testing
# Benchmark before/after if performance-related

# 5. Regression testing
# Run relevant test suites
```

## Debug Configuration Testing

### Essential Debug Configs

**Core Debug Options (always enable for testing)**:
```bash
# Essential debugging infrastructure
./scripts/config --enable CONFIG_DEBUG_KERNEL
./scripts/config --enable CONFIG_DEBUG_INFO

# Memory safety and leak detection  
./scripts/config --enable CONFIG_KASAN          # Kernel Address Sanitizer
./scripts/config --enable CONFIG_KMSAN          # Kernel Memory Sanitizer  
./scripts/config --enable CONFIG_UBSAN          # Undefined Behavior Sanitizer

# Lock debugging and deadlock detection
./scripts/config --enable CONFIG_LOCKDEP        # Lock dependency engine
./scripts/config --enable CONFIG_PROVE_LOCKING  # Lock correctness validator
./scripts/config --enable CONFIG_LOCKUP_DETECTOR # Detect soft/hard lockups

make olddefconfig
make -j$(nproc)
```

**Find Additional Debug Options**:
```bash
# Discover all debug configuration options
git grep -r DEBUG | grep Kconfig | head -20

# Memory debugging options
git grep -r DEBUG.*MEMORY | grep Kconfig

# Lock debugging options  
git grep -r DEBUG.*LOCK | grep Kconfig

# Filesystem debugging
git grep -r DEBUG.*FS | grep Kconfig
```

**Comprehensive Debug Configuration**:
```bash
# Advanced memory debugging
./scripts/config --enable CONFIG_DEBUG_SLAB
./scripts/config --enable CONFIG_DEBUG_SLAB_LEAK
./scripts/config --enable CONFIG_DEBUG_KMEMLEAK  
./scripts/config --enable CONFIG_DEBUG_PAGEALLOC
./scripts/config --enable CONFIG_DEBUG_VM
./scripts/config --enable CONFIG_DEBUG_VM_VMACHECKS
./scripts/config --enable CONFIG_DEBUG_VM_PGTABLE

# Advanced lock debugging
./scripts/config --enable CONFIG_DEBUG_SPINLOCK
./scripts/config --enable CONFIG_DEBUG_MUTEXES
./scripts/config --enable CONFIG_DEBUG_LOCK_ALLOC
./scripts/config --enable CONFIG_DEBUG_ATOMIC_SLEEP
./scripts/config --enable CONFIG_DEBUG_LOCKING_API_SELFTESTS

# Runtime checking
./scripts/config --enable CONFIG_DEBUG_OBJECTS
./scripts/config --enable CONFIG_DEBUG_OBJECTS_FREE
./scripts/config --enable CONFIG_DEBUG_OBJECTS_TIMERS
./scripts/config --enable CONFIG_DEBUG_OBJECTS_WORK
./scripts/config --enable CONFIG_DEBUG_OBJECTS_RCU_HEAD

# Build with all debug options
make olddefconfig
make -j$(nproc)
```

### Memory Testing Configs
```bash
./scripts/config --enable CONFIG_DEBUG_KMEMLEAK
./scripts/config --enable CONFIG_DEBUG_OBJECTS
./scripts/config --enable CONFIG_DEBUG_OBJECTS_FREE
./scripts/config --enable CONFIG_DEBUG_OBJECTS_TIMERS
./scripts/config --enable CONFIG_DEBUG_OBJECTS_WORK
./scripts/config --enable CONFIG_DEBUG_OBJECTS_RCU_HEAD
./scripts/config --enable CONFIG_DEBUG_OBJECTS_PERCPU_COUNTER
```

## Subsystem-Specific Testing

### Networking Patches
```bash
# netdev testing requirements
make allmodconfig
make htmldocs

# Network namespace testing
ip netns add test_ns
ip netns exec test_ns bash
# Test your changes here
ip netns del test_ns

# Traffic testing with iperf3/netperf
iperf3 -s &
iperf3 -c localhost -t 60

# Check for network warnings
dmesg | grep -E "(network|net|eth|tcp|udp)"
```

### Filesystem Patches
```bash
# Filesystem testing
make CONFIG_EXT4_FS=m CONFIG_XFS_FS=m CONFIG_BTRFS_FS=m

# Mount/unmount testing
sudo mount -t your_fs /dev/loop0 /mnt/test
# Perform file operations
sudo umount /mnt/test

# Stress testing with fsstress
fsstress -d /mnt/test -p 4 -n 1000
```

### Driver Patches
```bash
# Driver testing
make modules
sudo insmod your_driver.ko

# Test all driver operations
echo "test" > /sys/class/your_driver/test_attr
cat /sys/class/your_driver/status

# Unload testing
sudo rmmod your_driver.ko

# Check for resource leaks
cat /proc/slabinfo | grep your_driver
cat /proc/iomem | grep your_driver
```

### Memory Management Patches
```bash
# MM testing with debug enabled
./scripts/config --enable DEBUG_VM
./scripts/config --enable DEBUG_VM_VMACHECKS
./scripts/config --enable DEBUG_VM_PGTABLE
./scripts/config --enable DEBUG_PAGEALLOC

# Memory stress testing
stress-ng --vm 4 --vm-bytes 1G --timeout 60s

# Check for memory warnings
dmesg | grep -E "(memory|oom|page|slab)"
```

## Automated Testing

### Using kernel test suites
```bash
# Kernel selftests
make -C tools/testing/selftests run_tests

# Specific subsystem tests
make -C tools/testing/selftests/net run_tests
make -C tools/testing/selftests/vm run_tests
make -C tools/testing/selftests/bpf run_tests
```

### LTP (Linux Test Project)
```bash
git clone https://github.com/linux-test-project/ltp.git
cd ltp
make autotools
./configure
make -j$(nproc)
sudo make install

# Run relevant tests
sudo runltp -f syscalls
sudo runltp -f mm
sudo runltp -f net
```

### Kernel CI Integration
```bash
# 0-day testing (automatic)
# Intel's 0-day CI will test popular trees automatically

# Syzkaller fuzzing
# Set up syzkaller for complex subsystems

# KASAN/KTSAN integration
# Enable in your test kernels for memory safety
```

## Testing Documentation

### What to Include in Commit Messages
```
Testing performed:
- Compiled on x86_64 and arm64
- Loaded/unloaded module 50 times without issues
- Ran network stress test for 24 hours
- Verified with CONFIG_DEBUG_KERNEL=y
- No new warnings or errors in dmesg
- Performance impact: < 1% overhead
```

### Testing Checklist
```
[ ] Patch applies cleanly to target tree
[ ] Compiles without warnings (make W=1)
[ ] No checkpatch.pl errors or warnings
[ ] Static analysis (sparse/smatch) clean
[ ] Module loads/unloads properly (if applicable)
[ ] Basic functionality works as expected
[ ] No new dmesg warnings or errors
[ ] Performance impact measured (if applicable)
[ ] Cross-compilation tested (arm64/x86)
[ ] Debug kernel tested (CONFIG_DEBUG_KERNEL=y)
[ ] Relevant test suites pass
[ ] Documentation updated (if applicable)
```

## Performance Testing

### Benchmarking Guidelines
```bash
# Before applying patch
perf stat -r 10 your_benchmark

# Apply patch, rebuild, reboot

# After applying patch
perf stat -r 10 your_benchmark

# Compare results
# Report any regression > 5%
```

### Memory Usage Testing
```bash
# Monitor memory usage
/usr/bin/time -v your_test_program

# Check for memory leaks
valgrind --leak-check=full your_test_program

# Kernel memory monitoring
cat /proc/meminfo
cat /proc/slabinfo
```

## Continuous Integration

### Setting up test environment
```bash
# Use QEMU for testing
qemu-system-x86_64 \
    -kernel arch/x86/boot/bzImage \
    -initrd initramfs.cpio.gz \
    -m 2G \
    -smp 4 \
    -nographic \
    -append "console=ttyS0 root=/dev/ram0"

# Automated test script
#!/bin/bash
make allmodconfig
make -j$(nproc) || exit 1
make modules || exit 1
./scripts/checkpatch.pl --strict *.patch || exit 1
echo "All tests passed!"
```

## Common Testing Mistakes

### 1. Insufficient Testing
```bash
# WRONG - Only compile testing
make -j$(nproc)

# RIGHT - Comprehensive testing
make allmodconfig && make -j$(nproc)
make C=1 drivers/modified/
./scripts/checkpatch.pl --strict patch.patch
# + actual functionality testing
```

### 2. Wrong Test Environment
```bash
# WRONG - Testing on modified kernel with other patches
git apply my-other-patches.patch
git apply test-patch.patch

# RIGHT - Testing on clean upstream
git checkout upstream/master
git apply test-patch.patch
```

### 3. Not Testing Edge Cases
```bash
# WRONG - Only testing happy path
echo "normal_input" > /sys/module/test

# RIGHT - Testing error conditions
echo "invalid_input" > /sys/module/test
echo "" > /sys/module/test
echo "very_long_input_that_exceeds_buffer" > /sys/module/test
```

### 4. Ignoring Performance Impact
```bash
# WRONG - Not measuring performance
# Just submit the patch

# RIGHT - Measure and report
perf stat -r 10 benchmark_before
# apply patch
perf stat -r 10 benchmark_after
# Report: "No performance regression observed"
```

## Testing for Different Use Cases

### Server Workloads
```bash
# Test under high load
stress-ng --cpu 0 --vm 0 --io 4 --timeout 300s

# Network intensive
iperf3 -c server -P 10 -t 300

# Storage intensive
fio --name=test --rw=randrw --size=1G --bs=4k --numjobs=4
```

### Embedded Systems
```bash
# Test with limited memory
qemu-system-arm -m 64M ...

# Test with different page sizes
# ARM: 4K, 16K, 64K pages
# Test your patch with each
```

### Real-time Systems
```bash
# Test with RT kernel
git checkout linux-rt
apply_your_patch.sh
make -j$(nproc)

# Latency testing
cyclictest -p 80 -t 10 -n
```

## Reporting Test Results

### Good Testing Report
```
Testing performed on the attached patch:

Hardware:
- x86_64: Intel Core i7-9700K, 32GB RAM
- ARM64: Raspberry Pi 4, 8GB RAM

Software:
- Base: Linux 6.1-rc7
- Compiler: GCC 11.2, Clang 14.0
- Config: allmodconfig with DEBUG_KERNEL=y

Tests performed:
1. Compilation: PASS (both architectures)
2. Static analysis: PASS (sparse and smatch clean)
3. Style check: PASS (checkpatch.pl --strict)
4. Module load/unload: PASS (100 iterations)
5. Functionality test: PASS (all features work)
6. Stress test: PASS (24-hour run, no issues)
7. Performance: No regression (< 1% variance)

No new warnings or errors observed in dmesg.
```

### Poor Testing Report
```
Tested it, works fine.
```

Remember: Good testing is what separates professional kernel developers from script kiddies. Test thoroughly, document your testing, and never submit untested code.