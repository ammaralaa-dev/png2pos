/*
png2pos -- SECCOMP filter
*/

#ifndef _seccomp_h_
#define _seccomp_h_

#include <sys/prctl.h>
#include <linux/seccomp.h>
#include <linux/filter.h>
#include <linux/audit.h>
#include <stddef.h>
#include <sys/syscall.h>

/* used syscalls could be listed via strace command:
   strace -c -f -S name \
       ./png2pos -c -a R -r -p -s 1 -o /dev/null test*.png \
       2>&1 1>/dev/null | tail -n +3 | head -n -2 | awk '{print $(NF)}' */

#define ALLOW_SYSCALL(name) \
    BPF_JUMP(BPF_JMP + BPF_JEQ + BPF_K, __NR_##name, 0, 1), \
    BPF_STMT(BPF_RET + BPF_K, SECCOMP_RET_ALLOW)

struct sock_filter filter[] = {
    /* validate architecture */
    BPF_STMT(BPF_LD + BPF_W + BPF_ABS, offsetof(struct seccomp_data, arch)),
    BPF_JUMP(BPF_JMP + BPF_JEQ + BPF_K, AUDIT_ARCH_X86_64, 1, 0), /* FIXME */
    BPF_STMT(BPF_RET + BPF_K, SECCOMP_RET_KILL),
    /* load syscall */
    BPF_STMT(BPF_LD + BPF_W + BPF_ABS, offsetof(struct seccomp_data, nr)),
    /* allowed syscalls */
    ALLOW_SYSCALL(exit_group),
    ALLOW_SYSCALL(brk),
    ALLOW_SYSCALL(mmap),
    ALLOW_SYSCALL(mremap),
    ALLOW_SYSCALL(munmap),
    ALLOW_SYSCALL(ioctl),
    ALLOW_SYSCALL(access),
    ALLOW_SYSCALL(open),
    ALLOW_SYSCALL(read),
    ALLOW_SYSCALL(write),
    ALLOW_SYSCALL(close),
    ALLOW_SYSCALL(fstat),
    ALLOW_SYSCALL(lseek),
    /* default policy: die (trap for debug) */
#ifdef DEBUG
    BPF_STMT(BPF_RET + BPF_K, SECCOMP_RET_TRAP)
#else
    BPF_STMT(BPF_RET + BPF_K, SECCOMP_RET_KILL)
#endif
};
struct sock_fprog seccomp_filter_prog = {
    .len = sizeof filter / sizeof filter[0],
    .filter = filter
};

#endif
