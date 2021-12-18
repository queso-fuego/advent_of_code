;;;
;;; FreeBSD x86_64 asm, used with nasm
;;; AOC 2021 Day14 part 2
;;;
%define FALSE 0
%define TRUE 1
%define NEWLINE 10

extern printf, putchar

global main

section .text
main:
    cld             ; String ops will increment RSI/RDI

    mov rsi, data 
    mov rdi, template
    get_template:
        cmp byte [rsi], NEWLINE
        je add_template_to_pairs_array
        movsb
    jmp get_template

    add_template_to_pairs_array:
    inc rsi             ; Skip newline
    sub rdi, template+1 ; Size of template string-1
    mov rax, rdi

    xor rcx, rcx
    .loop:
        movsx rbx, byte [template+rcx]
        sub bl, 'A'
        shl bx, 3
        mov r12, rbx
        movsx rbx, byte [template+1+rcx]
        sub bl, 'A'
        imul rbx, rbx, 26*8
        add r12, rbx
        inc qword [letter_pair_counts+r12] 

        inc rcx
        cmp cl, al
    jl .loop

    ;; Add all pair insertion rules to array
    mov rdi, pair_rules
    add_rules_loop:
        cmp rsi, EOF
        jge steps
        movsw           ; 2 Characters
        add rsi, 4      ; Skip '-> '
        movsb           ; Insertion character
        inc rsi         ; Skip newline
        inc byte [num_rules]
    jmp add_rules_loop

    steps:
    xor r10, r10        ; Step counter
    step_loop:
        ;; Perform pair insertion rules for all pairs from string
        call apply_rules
        inc r10
        cmp r10b, 40
    jl step_loop

    ;; Get count of letters
    xor r12, r12
    add_letter_counts_loop:
        xor r13, r13
        .inner_loop:
            imul r14, r12, 8
            add r14, letter_counts
            
            imul r10, r12, 8
            imul r11, r13, 26*8
            add r10, r11
            add r10, letter_pair_counts
            mov rax, [r10]
            add [r14], rax              ; letter_counts[i] += letter pairs[i][j]

            inc r13
            cmp r13, 26
        jl .inner_loop

        inc r12
        cmp r12, 26
    jl add_letter_counts_loop

    ;; Add ending character of template string to letter count
    ;;   to fix off by one
    mov rdi, template
    xor rax, rax
    mov rcx, 26
    repne scasb     ; Search for ending null
    dec rdi         ; Point to null
    dec rdi         ; Point to last character
    mov al, byte [rdi]
    sub al, 'A'
    shl rax, 3
    inc qword [letter_counts+rax]

    ;; Print out letters and their counts, and get most/least common
    xor r12, r12
    print_letter_counts:
        mov rsi, r12
        add sil, 'A'
        call print_string

        imul r13, r12, 8
        mov rsi, qword [letter_counts+r13]
        cmp rsi, 0
        je .print                   ; Skip checking 0 values

        cmp rsi, [most_common]
        jbe .check_least            ; Unsigned comparison
        mov [most_common], rsi      ; Set new max

        .check_least:
        cmp rsi, [least_common]
        jae .print                  ; Unsigned comparison
        mov [least_common], rsi     ; Set new min

        .print:
        call print_int

        mov dil, NEWLINE
        call print_char

        inc r12
        cmp r12, 26
    jl print_letter_counts

    ;; Subtract least common quantity from most common quantity
    mov dil, NEWLINE
    call print_char

    mov rsi, [most_common]
    sub rsi, [least_common]
    call print_int

    mov dil, NEWLINE
    call print_char

    ret                 ; End program

;; Subroutine to apply pair insertion rules
apply_rules:
    ;; Clear copy array first
    mov rdi, letter_pairs_copy
    xor rax, rax
    mov rcx, 26*26
    rep stosq

    xor r12, r12
    .loop:
        imul r13, r12, 3

        movsx r14, byte [pair_rules+r13]
        sub r14b, 'A'
        shl r14, 3
        movsx r15, byte [pair_rules+1+r13]
        sub r15b, 'A'
        imul r15, r15, 26*8
        add r14, r15
        mov rax, [letter_pair_counts+r14]   ; Number of this pair in array

        movsx r14, byte [pair_rules+r13]
        sub r14b, 'A'
        shl r14, 3
        movsx r15, byte [pair_rules+2+r13]  ; First new pair
        sub r15b, 'A'
        imul r15, r15, 26*8
        add r14, r15
        add [letter_pairs_copy+r14], rax    ; Add number of original pairs to 1st new pair

        movsx r14, byte [pair_rules+2+r13]
        sub r14b, 'A'
        shl r14, 3
        movsx r15, byte [pair_rules+1+r13]  ; 2nd new pair
        sub r15b, 'A'
        imul r15, r15, 26*8
        add r14, r15
        add [letter_pairs_copy+r14], rax    ; Add number of original pairs to 2nd new pair

        inc r12
        cmp r12b, byte [num_rules]
    jl .loop

    ;; Move copy array to original array when done
    mov rsi, letter_pairs_copy
    mov rdi, letter_pair_counts
    mov rcx, 26*26
    rep movsq

    ret

;; Subroutine to print table of letter pairs
print_table:
    push rsp        ; 16 byte align stack
    mov dil, ' ' 
    call print_char
    pop rsp
    push rsp        ; 16 byte align stack
    mov dil, ' ' 
    call print_char
    pop rsp

    mov sil, 'A'
    .loop1:
        push rsp
        mov bl, sil
        call print_string
        pop rsp

        mov sil, bl
        inc sil
        cmp sil, 'Z'+1
    jl .loop1

    push rsp 
    mov dil, NEWLINE
    call print_char
    pop rsp

    xor r12, r12
    xor r14, r14
    xor rsi, rsi
    mov sil, 'A'
    .loop2_outer:
        push rsp
        mov bl, sil
        call print_string
        pop rsp
        mov sil, bl

        xor r13, r13
        mov r15, rsi
        .loop2_inner:
            push rsp
            mov rsi, [letter_pair_counts+r14]
            call print_int
            pop rsp

            add r14, 8
            inc r13
            cmp r13b, 26
        jl .loop2_inner
        mov rsi, r15

        push rsp 
        mov dil, NEWLINE
        call print_char
        pop rsp

        mov sil, bl
        inc rsi
        inc r12
        cmp r12b, 26
    jl .loop2_outer
        
    ret

;; Subroutine to print integer in RSI using C printf()
print_int:
    xor rax, rax            ; AL = # of vector arguments (0)
    lea rdi, [format_str]   ; 1st argument
    push rbx                ; 16byte align stack by pushing 8byte register before call
    push rbx
    call printf
    pop rbx                 ; 16byte align stack by popping 8byte register after call
    pop rbx
    ret

;; Print string at RSI using C printf()
print_string:
    xor rax, rax            ; AL = # of vector arguments (0)
    lea rdi, [format_str2]  ; 1st argument
    push rbx                ; 16byte align stack by pushing 8byte register before call
    push rbx
    call printf
    pop rbx                 ; 16byte align stack by popping 8byte register after call
    pop rbx
    ret

;; Subroutine to print char in RDI using C putchar()
print_char:
    push rsp        ; 16 byte align stack
    push rax
    call putchar
    pop rax         ; 16 byte align stack
    pop rsp
    ret

section .data
letter_pair_counts: times 26*26 dq 0    ; Array of all letter combinations
letter_pairs_copy: times 26*26 dq 0    ; Array of all letter combinations
template: times 26 db 0         ; Initial string
pair_rules: times 3*100 db 0    ; 2 Characters + insert character
num_rules: db 0
letter_counts: times 26 dq 0
most_common: dq 0
least_common: dq 0xFFFFFFFFFFFFFFFF

section .rodata
format_str: db "%llu ",0       
format_str2: db "%c ",0       ;; DEBUGGING

%include "input.asm"
;%include "test_input.asm"
