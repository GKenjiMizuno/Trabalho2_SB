section .text
    global print_message
    global print_allocation
    global calcular_alocacao

print_message:
    push ebp
    mov ebp, esp
    mov eax, 4          ; sys_write
    mov ebx, 1          ; stdout
    mov ecx, [ebp+8]    ; Ponteiro para a string
    mov edx, 100        ; Tamanho máximo da string
    int 0x80
    pop ebp
    ret

print_allocation:
    push ebp
    mov ebp, esp
    mov eax, 4          ; sys_write
    mov ebx, 1          ; stdout
    mov ecx, msg
    mov edx, msg_len
    int 0x80
    pop ebp
    ret

calcular_alocacao:
    push ebp
    mov ebp, esp
    
    mov eax, [ebp+8]  ; Tamanho do programa
    mov ebx, [ebp+12] ; Número de blocos
    mov ecx, [ebp+16] ; Ponteiro para os blocos
    mov edx, eax      ; Remaining size (tamanho restante)
    xor esi, esi      ; Índice do bloco

.loop:
    cmp edx, 0
    jle .done  ; Se não há mais espaço necessário, termina

    cmp esi, ebx
    jge .no_space  ; Se passou do número de blocos, não há espaço suficiente

    mov edi, [ecx + esi*8]    ; Pega endereço do bloco
    mov eax, [ecx + esi*8 + 4] ; Pega tamanho do bloco

    cmp edx, eax
    jle .allocate_full
    
    sub edx, eax
    push edi
    push eax
    call print_allocation
    add esp, 8
    jmp .next

.allocate_full:
    push edi
    push edx
    call print_allocation
    add esp, 8
    xor edx, edx  ; Finaliza a alocação

.next:
    inc esi
    jmp .loop

.no_space:
    push no_space_msg
    call print_message
    add esp, 4
    jmp .done

.done:
    pop ebp
    ret

section .data
    msg db "Bloco alocado.", 10, 0
    msg_len equ $ - msg
    alloc_msg db "Calculando alocacao...", 10, 0
    alloc_msg_len equ $ - alloc_msg
    no_space_msg db "Nao ha espaco suficiente na memoria.", 10, 0
