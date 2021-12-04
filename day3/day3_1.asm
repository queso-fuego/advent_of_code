;;;
;;; FreeBSD x86_64 asm, used with nasm
;;; AOC 2021 Day3 part 1
;;;
%define NUM_BITS 12

extern printf

global main

segment .text
main:
    lea rsi, [data]         ; Input data
    xor rax, rax            ; Temp value
    xor rbx, rbx            ; Counter
    xor rcx, rcx            ; Counter
    cld                     ; String ops will increment RSI/RDI
    
    .read_loop:
        mov rbx, -1          ; Counter
        mov cl, NUM_BITS
        .bits_loop:
            lodsb
            inc rbx
            inc rbx
            cmp al, 0           ; EOF?
            je .done_reading

            cmp al, '1'
            je .inc
            lea rdi, [zero_array]
            jmp .next

            .inc:
            lea rdi, [one_array]

            .next:
            add rdi, rbx
            inc word [rdi]
        loop .bits_loop
    jmp .read_loop

    .done_reading:
        xor rbx, rbx                ; Gamma rate
        lea rsi, [one_array]
        lea rdi, [zero_array]
        mov cl, NUM_BITS
        .compare_loop:
            xor rax, rax            ; Get bit position to set in gamma rate
            inc rax
            shl ax, cl
            shr ax, 1

            cmpsw                   ; Is the word at one_array > zero_array?
            jg .set_to_one          ; Yes, more 1s than 0s

            ;; Else more 0s than 1s 
            not ax                  ; Invert bits, 1s complement
            and bx, ax              ; Clear bit in gamma rate
            jmp .next_bit

            .set_to_one:
            or bx, ax               ; Set bit in gamma rate

            .next_bit:
        loop .compare_loop

        mov cx, bx

        not cx                 ; Invert bits (1's complement) for epsilon rate
        and cx, 0FFFh          ; Isolate lowest 12 bits

        imul rbx, rcx           ; BX = gamma *= epsilon (answer)

        ;; Print (RBX) as int with C printf()
        ;;   Using SYSV amd64 ABI
        xor rax, rax            ; AL = # of vector arguments (0)
        lea rdi, [format_str]   ; 1st argument
        mov rsi, rbx            ; 2nd argument
        push rbx                ; 16byte align stack by pushing 8byte register before call
        call printf
        pop rbx                 ; 16byte align stack by popping 8byte register after call

        ret

segment .rodata
format_str: db "%d",10,0       ;; DEBUGGING

segment .data
one_array: times NUM_BITS dw 0      
zero_array: times NUM_BITS dw 0    

%include "input.asm"
;%include "test_input.asm"
