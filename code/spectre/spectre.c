#include <stdlib.h>
#include <stdio.h>
#include <string.h>


#include "dependency1/unlock.h"
#include "dependency2/attacker.h"

int main() {
    printf("\e[1;1H\e[2J");
    printf("-- Starting exploit.\n");

    char *test2 = malloc(sizeof(char) * 40);
    strcpy(test2, "normal data");
    printf("memory at %p: %.40s\n", test2, test2);
    unlock();
    free(test2);

    const int success = attack(test2);
    return success;
}
