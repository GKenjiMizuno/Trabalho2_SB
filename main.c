#include <stdio.h>
#include <stdlib.h>

/* Declarações das funções em Assembly */
extern void calcular_alocacao(int tamanho, int num_blocos, int *blocos);
extern void print_message(const char *msg);

/* Mensagem de uso caso parâmetros estejam incorretos */
static const char *msg_uso = 
    "Uso correto:\n"
    "  ./carregador <tamanho_programa> <endereco_1> <tam_bloco_1> "
    "[<endereco_2> <tam_bloco_2> ... ate 4 blocos]\n\n"
    "Exemplo:\n"
    "  ./carregador 125 100 500 4000 300 20000 125 30000 345\n\n";

int main(int argc, char *argv[])
{
    /*
      argc esperado:
        argv[0] = "./carregador"
        argv[1] = <tamanho_programa>
        depois pares: <endereco> <tamanho_do_bloco> ...
    */
    
    // Precisamos pelo menos de argv[1] (tamanho) + 1 par de bloco => 3 parâmetros
    // E a contagem de blocos deve ser " (argc - 2) / 2 "
    if (argc < 3 || ((argc - 2) % 2) != 0) {
        print_message(msg_uso);
        return 1;
    }

    // argv[1] => tamanho do programa
    int program_size = atoi(argv[1]);

    // Número de blocos => (argc - 2) / 2
    int num_blocks = (argc - 2) / 2;

    // Aloca array local para endereços e tamanhos
    // Serão num_blocks pares, cada par = (endereco, tamanho)
    int blocks[num_blocks * 2];

    // Preenche o array blocks[i]
    // i = 0 => argv[2]
    // i = 1 => argv[3]
    // ...
    for (int i = 0; i < num_blocks * 2; i++) {
        blocks[i] = atoi(argv[i + 2]);
    }

    // Chama a função em Assembly
    calcular_alocacao(program_size, num_blocks, blocks);

    return 0;
}
