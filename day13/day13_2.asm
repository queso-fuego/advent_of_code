;;;
;;; FreeBSD x86_64 asm, used with nasm
;;; AOC 2021 Day13 part 2
;;;
%define FALSE 0
%define TRUE 1
%define MAX_DOTS 1000

extern putchar

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
        xor r10, r10        ; Reset dots counter
        lodsb               ; Move past equal '='
        lodsw               ; Read Fold X value
        mov [max_x], ax     ; Set new Max X
        mov r8, dots        ; Dots array index, X values

        .fold_x_loop:
        push rax            ; Save rax
        movsx r9, word [r8] ; Yes, get X value
        sub r9w, ax         ; X - fold X (distance to fold)
        movsx rbx, ax       ; Fold X
        sub bx, r9w         ; Fold X - distance
        cmp ax, [r8]        ; Fold X smaller than X value?
        jge .x_inc          ; No, go on

        ;; Check if duplicate 
        mov rdi, dots
        movsx rax, word [r8+2]  ; Copy point Y value
        shl rax, 16             ; Make room for lower word
        mov ax, bx              ; Check for new X value
        movsx rcx, word [dots_max]  ; Max number of dots to check
        repne scasd
        jecxz .set_x_reflection ; RCX = 0, did not find point, go on
        mov dword [rdi-4], -1   ; Set point to -1, won't count it again

        .set_x_reflection:
        mov [r8], bx            ; Set dot's X value to it's reflection

        .x_inc:
        pop rax             ; Restore rax
        add r8, 4           ; Next dot's X value
        inc r10
        cmp r10w, [dots_max]    ; Check up to dots_max
        jl .fold_x_loop 
        jmp .get_next_fold

        .fold_y:
        xor r10, r10        ; Reset dots counter
        lodsb               ; Move past equal '='
        lodsw               ; Read Fold Y value
        mov [max_y], ax     ; Set new Max Y
        mov r8, dots+2      ; Dots array index, Y values

        .fold_y_loop:
        push rax            ; Save rax
        movsx r9, word [r8] ; Get Y value
        sub r9w, ax         ; Y - fold Y (distance to fold)
        movsx rbx, ax       ; Fold Y
        sub bx, r9w         ; Fold Y - distance
        cmp ax, [r8]        ; Fold Y smaller than Y value?
        jge .y_inc          ; No, go on

        ;; Check if duplicate 
        mov rdi, dots
        movsx rax, bx           ; Check for new Y value
        shl rax, 16             ; Make room for lower word
        mov ax, [r8-2]          ; Copy point X value
        movsx rcx, word [dots_max]  ; Max number of dots to check
        repne scasd
        jecxz .set_y_reflection ; RCX = 0, did not find point, go on
        mov dword [rdi-4], -1   ; Set point to -1, won't count it again

        .set_y_reflection:
        mov [r8], bx            ; Set dot's Y value to it's reflection

        .y_inc:
        pop rax                 ; Restore rax
        add r8, 4               ; Next dot's Y value
        inc r10
        cmp r10w, [dots_max]    ; Check up to dots_max
        jl .fold_y_loop
        jmp .get_next_fold

    done:
    ;; Remove all dots outside boundaries
    mov rdi, dots
    mov ax, [max_x]
    mov bx, [max_y]
    movsx rcx, word [dots_max]  
    .remove_loop:
        cmp ax, [rdi]           ; Is X value out of bounds?
        jl .remove_dot
        cmp bx, [rdi+2]         ; Is Y value out of bounds?
        jge .next_1

        .remove_dot:
        mov dword [rdi], -1

        .next_1:
        add rdi, 4
    loop .remove_loop

    ;; Get 8 capital letters spelled out after all folding is done
    xor rbx, rbx            ; X counter
    xor rdx, rdx            ; Y counter
    .outer_print_loop:
        movsx rcx, word [dots_max]
        mov rdi, dots
        movsx rax, dx       ; Y
        shl rax, 16
        mov ax, bx          ; X
        repne scasd         ; Search for RAX X,Y value in dots
        jecxz .print_dot    ; Dot is not there, print a "blank"

        mov dil, '#'        ; Else print pound sign '#' for visible dot
        jmp .print_next

        .print_dot:
        mov dil, '.'        ; Print period '.' for blank

        .print_next:
        push rax            ; Save RAX
        push rax            ; 16 byte align stack
        push rdx            ; Save RDX
        call putchar
        pop rdx             ; Restore RDX
        pop rax             ; 16 byte align stack
        pop rax             ; Restore RAX

        inc rbx
        cmp bx, [max_x]
        jl .outer_print_loop
        xor rbx, rbx        ; Next line 

        push rax            ; Save RAX
        push rax            ; 16 byte align stack
        push rdx            ; Save RDX
        mov dil, 10         ; Newline
        call putchar
        pop rdx             ; Restore RDX
        pop rax             ; 16 byte align stack
        pop rax             ; Restore RAX

        inc rdx
        cmp dx, [max_y]
    jl .outer_print_loop

    ret                     ; End program

section .data
dots: times MAX_DOTS dd -1      ; Set of points - (X as word, Y as word)
dots_max: dw 0
max_x: dw 0                     ; X boundary
max_y: dw 0                     ; Y boundary

section .rodata
%include "input.asm"
;%include "test_input.asm"
