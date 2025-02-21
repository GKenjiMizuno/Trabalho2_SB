
SECTION .data

msg_calculo    db "Calculando alocacao...", 10, 0
msg_no_space   db "Nao ha espaco suficiente na memoria.", 10, 0
msg_newline    db 10, 0
msg_alocado_de db "Alocado de ", 0
msg_ate        db " ate ", 0
zero_str db "0", 0

SECTION .text
global calcular_alocacao
global print_message
global print_allocation
global print_int

print_message:
    push ebp
    mov ebp, esp

    mov ecx, [ebp+8]  
    xor edx, edx
    xor eax, eax

.count_length:
    mov al, [ecx+edx]
    cmp al, 0
    je .length_found
    inc edx
    jmp .count_length

.length_found:
    mov eax, 4  
    mov ebx, 1   
    int 0x80

    pop ebp
    ret

print_int:
    push ebp
    mov  ebp, esp

    push ebx
    push esi
    push edi

    mov eax, [ebp+8]

    cmp eax, 0
    jne .convert
    push dword zero_str
    call print_message
    add esp, 4
    jmp .done

.convert:
    sub esp, 16
    mov edi, esp
    xor ecx, ecx

.loop_div:
    xor edx, edx
    mov ebx, 10
    div ebx             
    add dl, '0'
    mov [edi], dl
    inc edi
    inc ecx
    cmp eax, 0
    jne .loop_div

    mov byte [edi], 0

    mov esi, esp
    mov edi, esp
    add edi, ecx
    dec edi

.reverse:
    cmp esi, edi
    jge .reversed
    mov al, [esi]
    mov ah, [edi]
    mov [esi], ah
    mov [edi], al
    inc esi
    dec edi
    jmp .reverse

.reversed:
    push esp
    call print_message
    add esp, 4

    add esp, 16

.done:
    pop edi
    pop esi
    pop ebx
    pop ebp
    ret


print_allocation:
    push ebp
    mov ebp, esp

    push ebx
    push edi

    mov eax, [ebp+8]   
    mov ebx, [ebp+12]  
    add eax, ebx
    sub eax, 1       

    push dword msg_alocado_de
    call print_message
    add esp, 4

    push dword [ebp+8]
    call print_int
    add esp, 4

    push dword msg_ate
    call print_message
    add esp, 4

    push eax
    call print_int
    add esp, 4

    push dword msg_newline
    call print_message
    add esp, 4

    pop edi
    pop ebx
    pop ebp
    ret


calcular_alocacao:
    push ebp
    mov ebp, esp

    push ebx
    push esi
    push edi


    push dword msg_calculo
    call print_message
    add esp, 4

    mov edx, [ebp+8]    
    mov ebx, [ebp+12]    
    mov ecx, [ebp+16]    
    xor esi, esi

.loop:
    cmp edx, 0
    jle .done   

    cmp esi, ebx
    jge .no_space


    mov ecx, [ebp+16]

    mov edi, [ecx + esi*8]     
    mov eax, [ecx + esi*8 + 4]

    cmp edx, eax
    jle .allocate_full


    sub edx, eax
    push eax  
    push edi 
    call print_allocation
    add esp, 8

    jmp .next

.allocate_full:
    push edx
    push edi
    call print_allocation
    add esp, 8

    xor edx, edx

.next:
    inc esi
    jmp .loop

.no_space:
    push dword msg_no_space
    call print_message
    add esp, 4
    jmp .done

.done:
    pop edi
    pop esi
    pop ebx
    pop ebp
    ret
