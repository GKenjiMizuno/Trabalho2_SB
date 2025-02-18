#include <stdio.h>
#include <stdlib.h>

extern void print_message(const char *msg);
extern void print_allocation(int start, int end);
extern void calcular_alocacao(int tamanho, int num_blocos, int *blocos);

int main(int argc, char *argv[]) {
    if (argc < 3 || (argc - 2) % 2 != 0) {
        print_message("Uso: <tamanho_programa> <blocos>\n");
        return 1;
    }

    int program_size = atoi(argv[1]);
    int num_blocks = (argc - 2) / 2;
    int blocks[num_blocks * 2];
    
    for (int i = 0; i < num_blocks * 2; i++) {
        blocks[i] = atoi(argv[i + 2]);
    }
    
    calcular_alocacao(program_size, num_blocks, blocks);
    return 0;
}
