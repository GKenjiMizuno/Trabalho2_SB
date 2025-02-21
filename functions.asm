;=============================================================================
; Arquivo: carregador.asm
; Exemplo de uso: nasm -f elf32 carregador.asm && gcc -m32 carregador.o carregador.c -o carregador
;=============================================================================

SECTION .data

msg_calculo    db "Calculando alocacao...", 10, 0
msg_no_space   db "Nao ha espaco suficiente na memoria.", 10, 0
msg_newline    db 10, 0
msg_alocado_de db "Alocado de ", 0
msg_ate        db " ate ", 0

SECTION .bss
; Aqui poderíamos colocar buffers se quisermos para conversão de strings, mas
; faremos tudo de forma local nas funcoes. (Ex: 'resb 32' etc. se precisasse)

SECTION .text
global calcular_alocacao
global print_message
global print_allocation
global print_int

;----------------------------------------------------------------------------
; Função: print_message(const char *msg)
; Recebe no topo da pilha (ebp+8) um ponteiro para string terminada em 0
; Imprime a string toda usando sys_write (int 0x80).
;----------------------------------------------------------------------------
print_message:
    push ebp
    mov ebp, esp

    ; ecx = ponteiro para msg
    mov ecx, [ebp+8]

    ; Precisamos descobrir o tamanho da string (até encontrar byte 0).
    xor edx, edx         ; edx = 0 => será usado para contar length
    xor eax, eax

.count_length:
    mov al, [ecx+edx]    ; lê 1 byte
    cmp al, 0
    je .length_found
    inc edx
    jmp .count_length

.length_found:
    ; Agora em ecx = ponteiro, edx = length
    ; Chamada de sistema sys_write:
    ;   eax = 4 (sys_write), ebx = 1 (STDOUT), ecx = endereço, edx = tamanho
    mov eax, 4
    mov ebx, 1
    int 0x80

    pop ebp
    ret

;----------------------------------------------------------------------------
; Função: print_int(int valor)
; Imprime o valor em decimal (sem \n no final).
; Parametro em [ebp+8].
; Não lida com negativo, assume >= 0.
;----------------------------------------------------------------------------
print_int:
    push ebp
    mov ebp, esp

    push ebx
    push esi
    push edi

    ; valor em EAX
    mov eax, [ebp+8]

    ; Se for 0, imprime '0' e retorna.
    cmp eax, 0
    jne .convert

    ; imprime "0"
    push dword zero_str    ; string "0"
    call print_message
    add esp, 4            ; balancear a pilha
    jmp .fim

.convert:
    ; Precisamos converter para string em decimal.
    ; Faremos num buffer local. Max 10 dígitos p/ 32 bits (até 4294967295).
    sub esp, 16           ; reserva um pequeno espaço para buffer
    mov edi, esp          ; edi aponta para o inicio do buffer local

    ; Zera contagem de caracteres
    xor ecx, ecx          ; ecx = 0 => count

.loop_convert:
    ; Divide EAX por 10 => resto (em EDX) + '0'
    xor edx, edx
    mov ebx, 10
    div ebx               ; (edx:eax) / ebx => EAX=quociente, EDX=resto
    add dl, '0'
    mov [edi], dl         ; grava caractere
    inc edi
    inc ecx               ; conta dígitos
    cmp eax, 0
    jne .loop_convert

    ; Agora temos a string invertida no buffer [esp..esp+ecx-1].
    ; Precisamos inverter para imprimir na ordem correta.

    ; Termina string com 0
    mov byte [edi], 0

    ; Inverte in-place
    ;  - start em (esp)
    ;  - end em (esp + ecx - 1)
    mov esi, esp          ; ptr inicio
    mov edi, esp
    add edi, ecx
    dec edi               ; agora edi aponta p/ último char (não o 0)
    
.reverse_loop:
    cmp esi, edi
    jge .done_reverse
    mov al, [esi]
    mov ah, [edi]
    mov [esi], ah
    mov [edi], al
    inc esi
    dec edi
    jmp .reverse_loop

.done_reverse:
    ; Agora buffer local [esp] tem a string decimal correta.
    ; Precisamos imprimir usando print_message. Então passamos o ponteiro.

    push esp      ; push endereço do buffer local
    call print_message
    add esp, 4

    ; Libera o espaço do buffer
    add esp, 16

.fim:

    pop edi
    pop esi
    pop ebx
    pop ebp
    ret

; String "0" isolada
section .data
zero_str db "0", 0

section .text

;----------------------------------------------------------------------------
; Função: print_allocation(int start, int size)
; Imprime algo como: "Alocado de <start> ate <end>\n"
;   onde end = start + size - 1
;----------------------------------------------------------------------------
print_allocation:
    push ebp
    mov ebp, esp
    push ebx
    push edi

    ; start = [ebp+8], size = [ebp+12]
    ; end = start + size - 1
    mov eax, [ebp+8]      ; start
    mov ebx, [ebp+12]     ; size
    add eax, ebx
    sub eax, 1            ; end = start + size - 1

    ; 1) "Alocado de "
    push dword msg_alocado_de
    call print_message
    add esp, 4

    ; 2) imprimir start
    push dword [ebp+8]
    call print_int
    add esp, 4

    ; 3) " ate "
    push dword msg_ate
    call print_message
    add esp, 4

    ; 4) imprimir end
    push eax
    call print_int
    add esp, 4

    ; 5) imprimir \n
    push dword msg_newline
    call print_message
    add esp, 4

    pop edi
    pop ebx 
    pop ebp
    ret

; Faz a lógica de alocar o 'tamanho' do programa, usando até 'num_blocos' blocos
; Caso não caiba, imprime msg_no_space.
; Caso caiba parcial ou totalmente, chama print_allocation pra cada fatia.

calcular_alocacao:
    push ebp
    mov ebp, esp

    ; Parâmetros:
    ;   [ebp+8] = tamanho do programa (int)
    ;   [ebp+12] = num_blocos (int)
    ;   [ebp+16] = ponteiro para array de blocos (int*)

    ; Imprime "Calculando alocacao..."
    push dword msg_calculo
    call print_message
    add esp, 4

    mov edx, [ebp+8]    ; edx = tamanho restante do programa
    mov ebx, [ebp+12]   ; ebx = num_blocos
    mov ecx, [ebp+16]   ; ecx = ponteiro para blocos (int*)

    xor esi, esi        ; esi = índice do bloco (0..num_blocos-1)

.loop:
    cmp edx, 0
    jle .done           ; se edx <= 0, acabou de alocar tudo

    cmp esi, ebx
    jge .no_space       ; se excedeu número de blocos, não há espaço suficiente

    mov ecx, [ebp+16]

    ; blocos[esi*2]     => endereço do bloco
    ; blocos[esi*2 +1]  => tamanho do bloco
    ; cada par ocupa 2 * 4 bytes = 8 bytes
    mov edi, [ecx + esi*8]      ; edi = endereço do bloco
    mov eax, [ecx + esi*8 + 4]  ; eax = tamanho do bloco

    ; Se o que falta (edx) couber no bloco, aloca só edx
    cmp edx, eax
    jle .allocate_full

    ; Caso contrário, aloca o bloco todo
    ; -> Impressão: start=edi, size=eax
    sub edx, eax  ; retira esse bloco inteiro do que falta
    push eax
    push edi
    call print_allocation
    add esp, 8

    jmp .next

.allocate_full:
    ; Aqui coube tudo (edx <= eax), então aloca somente 'edx' nesse bloco
    ; -> Impressão: start=edi, size=edx
    push edx
    push edi
    call print_allocation
    add esp, 8

    xor edx, edx  ; zera => não falta mais nada

.next:
    inc esi
    jmp .loop

.no_space:
    push dword msg_no_space
    call print_message
    add esp, 4
    jmp .done

.done:
    pop ebp
    ret
