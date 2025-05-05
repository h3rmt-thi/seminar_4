#include "unlock.h"

#include <stdlib.h>
#include <stdio.h>

void unlock() {
    char *secret = malloc(sizeof(char) * 60);

    FILE *file = fopen("secret.txt", "r");
    fgets(secret, 60, file);
    fclose(file);
    printf("secret at %p: %.40s\n", secret, secret);
    free(secret);
    printf("secret at %p after free: %.40s\n\n", secret, secret);
}
