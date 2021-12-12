;;;
;;; FreeBSD x86_64 asm, used with nasm
;;; AOC 2021 Day10 part 1
;;;
%define LINE_END 10     ; Newline, \n

extern printf

global main

segment .text
main:
    cld                 ; String ops will increment RSI/RDI
    xor rbx, rbx
    xor rcx, rcx
    xor r8, r8          ; Final sum

    mov rsi, data  
    next_line:
        ;; Clear stack array
        mov cl, 200
        xor rax, rax
        mov rdi, bracket_stack
        rep stosb
        mov rdi, bracket_stack

        next_char:
            lodsb
            cmp rsi, EOF
            jg done
        
            cmp al, LINE_END
            je next_line

            cmp al, '('
            jne .check_sqbr
            mov byte [rdi], ')'
            inc rdi
            jmp next_char

            .check_sqbr:
            cmp al, '['
            jne .check_crbr
            mov byte [rdi], ']'
            inc rdi
            jmp next_char

            .check_crbr:
            cmp al, '{'
            jne .check_anbr
            mov byte [rdi], '}'
            inc rdi
            jmp next_char

            .check_anbr:
            cmp al, '<'
            jne .check_legal
            mov byte [rdi], '>'
            inc rdi
            jmp next_char

            .check_legal:
            ;; "Pop" last char from stack
            dec rdi
            mov bl, [rdi]
            mov byte [rdi], 0
            cmp al, bl
            je next_char

            .illegal:
            cmp al, ')'
            jne .illegal_sqbr
            add r8, 3
            jmp .read_rest_of_line

            .illegal_sqbr:
            cmp al, ']'
            jne .illegal_crbr
            add r8, 57
            jmp .read_rest_of_line

            .illegal_crbr:
            cmp al, '}'
            jne .illegal_anbr
            add r8, 1197
            jmp .read_rest_of_line

            .illegal_anbr:
            add r8, 25137

            .read_rest_of_line:
            lodsb
            cmp al, LINE_END
            jne .read_rest_of_line
            jmp next_line

    done:
        mov rcx, r8

    ;; Print integer in RCX using C printf()
    ;;   Using SYSV amd64 ABI
    print_int:
        xor rax, rax            ; AL = # of vector arguments (0)
        lea rdi, [format_str]   ; 1st argument
        mov rsi, rcx            ; 2nd argument
        push rbx                ; 16byte align stack by pushing 8byte register before call
        call printf
        pop rbx                 ; 16byte align stack by popping 8byte register after call

        ret                     ; End program

segment .data
bracket_stack: times 200 db 0

segment .rodata
format_str: db "%lld",10,0       

%include "input.asm"
;%include "test_input.asm"
