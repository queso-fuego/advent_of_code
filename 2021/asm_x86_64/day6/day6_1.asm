;;;
;;; FreeBSD x86_64 asm, used with nasm
;;; AOC 2021 Day6 part 1
;;;
%define MAX_INDEX 9

extern printf

global main

segment .text
main:
    lea rsi, [data]     ; Input 
    mov r8, 80          ; Day counter   
    xor r9, r9          ; Fish counter

    cld                 ; String ops will increment RSI/RDI
    
    initial_read_loop:
        cmp rsi, EOF
        jge fish_loop
        xor rax, rax
        lodsb
        shl al, 3               ; Multiply by 8 for quadwords
        lea rdi, [fish]
        add rdi, rax
        inc qword [rdi]         ; Fish timer index + 1
    jmp initial_read_loop

    fish_loop:
        ;; Reset copy table
        mov rcx, MAX_INDEX
        lea rdi, [fish_copy]
        xor rax, rax
        rep stosq

        ;; Add timer 0 fish to timer 8 and timer 6 fish
        ;;   in copy table
        mov rax, [fish]
        add [fish_copy+48], rax ; Timer 6
        add [fish_copy+64], rax ; Timer 8

        lea rsi, [fish+8] ; RSI starts at index 1
        lea rdi, [fish_copy]
        mov rcx, 1          ; Start at index 1
        .move_loop:
            cmp cl, MAX_INDEX
            jge .move_done
            lodsq           ; RAX = [RSI] & add RSI, 8
            add [rdi], rax  ; Fish copy table += fish table
            add rdi, 8      ; Next index in copy table
            inc rcx
        jmp .move_loop

        .move_done:
            ;; Copy the new values in copy table to fish table
            mov rcx, MAX_INDEX
            lea rsi, [fish_copy]
            lea rdi, [fish]
            rep movsq           ; [RDI] = [RSI] & inc both by 8

            dec r8              ; Day count - 1
        jnz fish_loop

    done:
        ;; Count fish
        lea rsi, [fish]
        mov rcx, MAX_INDEX
        .count_loop:
            lodsq
            add r9, rax
        loop .count_loop

        mov rcx, r9             ; Final amount of fish 

    ;; Print integer in RCX using C printf()
    ;;   Using SYSV amd64 ABI
    print_answer:
        xor rax, rax            ; AL = # of vector arguments (0)
        lea rdi, [format_str]   ; 1st argument
        mov rsi, rcx            ; 2nd argument
        push rbx                ; 16byte align stack by pushing 8byte register before call
        call printf
        pop rbx                 ; 16byte align stack by popping 8byte register after call

        ret                     ; End program

segment .data
fish: times MAX_INDEX dq 0    ; Count of each fish timer 0-MAX
fish_copy: times MAX_INDEX dq 0    ; Count of each fish timer 0-MAX

segment .rodata
format_str: db "%lld",10,0       

%include "input.asm"
;%include "test_input.asm"
