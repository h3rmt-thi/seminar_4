#include "unlock.h"

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdbool.h>

int size = 70;

void unlock(bool freeSec, bool override) {
    char *secret = malloc(sizeof(char) * size);

    FILE *file = fopen("secret.txt", "r");
    fgets(secret, size, file);
    fclose(file);
    printf("secret at %p: %s\n", secret, secret);
    
    if (freeSec) {
        if (override) {
            memset(secret, 30, size);
            printf("secret overridden with 0s\n");
        }
        free(secret);
        printf("freeing secret\n");
    } else {
        printf("not freeing secret\n");
    }
    
    printf("secret at %p (after free): %.60s\n\n", secret, secret);
}
