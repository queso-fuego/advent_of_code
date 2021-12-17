;;;
;;; FreeBSD x86_64 asm, used with nasm
;;; AOC 2021 Day13 part 1
;;;
%define FALSE 0
%define TRUE 1
%define MAX_DOTS 1000

extern printf

global main

section .text
main:
    cld             ; String ops will increment RSI/RDI

    xor rax, rax    ; Temp
    mov rdi, dots   ; RDI = dots array index
    xor r10, r10    ; Dots counter

    mov rsi, data 
    dots_loop:
        ;; Set dots in grid
        cmp dword [rsi], "fold" ; Reached 'fold...' lines yet?
        je folds
        movsd                   ; Store X/Y value in dots array
        inc r10                 ; Number of dots += 1
    jmp dots_loop

    folds:
        mov [dots_max], r10w ; Store maximum number of dots
        .get_next_fold:
        lodsb               ; Read until x, y, or EOF is found
        cmp rsi, EOF
        jge done

        cmp al, 'x'
        je .fold_x
        cmp al, 'y'
        je .fold_y
        jmp .get_next_fold  ; Continue

        .fold_x:
        movsx r12, word [dots_max]
        xor r10, r10        ; Reset dots counter
        lodsb               ; Move past equal '='
        lodsw               ; Read Fold X value
        mov r8, dots        ; Dots array index, X values

        .fold_x_loop:
        cmp ax, [r8]        ; Fold X smaller than X value?
        jge .x_inc          ; No, go on

        movsx r9, word [r8] ; Yes, get X value
        sub r9w, ax         ; X - fold X (distance to fold)
        movsx rbx, ax       ; Fold X
        sub bx, r9w         ; Fold X - distance

        ;; Check if duplicate 
        mov r9, dots
        xor r11, r11
        movsx r10, word [r8+2] ; Copy point Y value
        shl r10, 16         ; Make room for lower word
        mov r10w, bx        ; Check for new X value
        .fold_x_check_duplicate:
            cmp r10d, [r9]
            jne .fold_x_duplicate_inc
            dec word [dots_max] ; Don't count duplicate point
            jmp .x_inc

            .fold_x_duplicate_inc:
            add r9, 4
            inc r11
            cmp r11w, r12w      ; Check up to dots_max
        jl .fold_x_check_duplicate

        .fold_x_done_checking:
        mov [r8], bx        ; Set dot's X value to it's reflection

        .x_inc:
        add r8, 4           ; Next dot's X value
        inc r10
        cmp r10w, r12w      ; Check up to dots_max
        jl .fold_x_loop 
        jmp done            ; Part 1 only needs 1 fold

        .fold_y:
        movsx r12, word [dots_max]
        xor r10, r10        ; Reset dots counter
        lodsb               ; Move past equal '='
        lodsw               ; Read Fold Y value
        mov r8, dots+2      ; Dots array index, Y values

        .fold_y_loop:
        cmp ax, [r8]        ; Fold Y smaller than Y value?
        jge .y_inc          ; No, go on

        movsx r9, word [r8] ; Yes, get Y value
        sub r9w, ax         ; Y - fold Y (distance to fold)
        movsx rbx, ax       ; Fold Y
        sub bx, r9w         ; Fold Y - distance

        ;; Check if duplicate 
        mov r9, dots
        xor r11, r11
        movsx r10, bx           ; Check for new Y value
        shl r10, 16             ; Make room for lower word
        mov r10w, [r8-2]        ; Copy point X value
        .fold_y_check_duplicate:
            cmp r10d, [r9]
            jne .fold_y_duplicate_inc
            dec word [dots_max] ; Don't count duplicate point
            jmp .y_inc

            .fold_y_duplicate_inc:
            add r9, 4
            inc r11
            cmp r11w, r12w      ; Check up to dots_max
        jl .fold_y_check_duplicate

        .fold_y_done_checking:
        mov [r8], bx        ; Set dot's Y value to it's reflection

        .y_inc:
        add r8, 4           ; Next dot's Y value
        inc r10
        cmp r10w, r12w      ; Check up to dots_max
        jl .fold_y_loop

    done:
    movsx rcx, word [dots_max]     ; Answer

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

section .data
dots: times MAX_DOTS dd 0       ; Set of points - (X as word, Y as word)
dots_max: dw 0

section .rodata
format_str: db "%lld",10,0       

%include "input.asm"
;%include "test_input.asm"
