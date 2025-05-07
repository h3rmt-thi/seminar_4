#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdbool.h>

#include "dependency1/unlock.h"
#include "dependency2/attacker.h"

int len = 120;

int main() {
    printf("\e[1;1H\e[2J");
    printf("-- Starting exploit.\n");

    bool debug = false;
    const char *spec_debug_env = getenv("SPEC_DEBUG");
    if (spec_debug_env != NULL && strcmp(spec_debug_env, "1") == 0) {
        debug = true;
    }

    bool freeSec = false;
    const char *spec_n_free = getenv("SPEC_FREE");
    if (spec_n_free != NULL && strcmp(spec_n_free, "1") == 0) {
        freeSec = true;
    }

    bool override = false;
    const char *spec_ovr = getenv("SPEC_OVERRRIDE");
    if (spec_ovr != NULL && strcmp(spec_ovr, "1") == 0) {
        override = true;
    }

    const char *len_env = getenv("SPEC_LEN");
    if (len_env != NULL) {
        int env_len = atoi(len_env);
        if (env_len > 0) {
            len = env_len;
        } else {
            printf("Invalid SPEC_LEN value, using default length %d\n", len);
        }
    }
    char *output = malloc(len + 1);

    char *test2 = malloc(sizeof(char) * 40);
    strcpy(test2, "normal data");
    printf("memory at %p: %s\n", test2, test2);
    free(test2);

    unlock(freeSec, override);

    const int success = attack(test2, len, output, debug);
    return success;
}
