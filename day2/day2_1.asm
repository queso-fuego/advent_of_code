;;;
;;; FreeBSD x86_64 asm, used with nasm
;;; AOC 2021 Day2 part 1
;;;
extern printf

global main

segment .text
main:
    lea rsi, [data]         ; Input data
    xor rax, rax            ; Temp value
    xor rbx, rbx            ; horizontal position
    xor rcx, rcx            ; Counter
    xor rdx, rdx            ; depth
    cld                     ; String ops will increment RSI/RDI

    .loop:
        cmp byte [rsi], 0   ; EOF?
        je .done_reading

        ;; Check direction
        push rsi
        lea rdi, [forward_str]
        mov cl, forward_str.len
        repe cmpsb
        je .forward
        pop rsi

        push rsi
        lea rdi, [up_str]
        mov cl, up_str.len
        repe cmpsb
        je .up
        pop rsi

        push rsi
        lea rdi, [down_str]
        mov cl, down_str.len
        repe cmpsb
        je .down
        pop rsi
        
        .forward:
            mov rdi, rsi    ; Save data position
            pop rsi         ; Restore stack
            mov rsi, rdi    ; Restore data position

            lodsb           ; Get number
            add rbx, rax    ; Add to horizontal position

            jmp .loop

        .up:
            mov rdi, rsi    ; Save data position
            pop rsi         ; Restore stack
            mov rsi, rdi    ; Restore data position

            lodsb           ; Get number
            sub rdx, rax    ; Subtract from depth

            jmp .loop

        .down:
            mov rdi, rsi    ; Save data position
            pop rsi         ; Restore stack
            mov rsi, rdi    ; Restore data position

            lodsb           ; Get number
            add rdx, rax    ; Add to depth
    jmp .loop

    .done_reading:
        ;; Multiply horizontal position by depth
        imul rbx, rdx           ; RBX = (horz pos *= depth)
        mov rcx, rbx            ; RCX = Result

        ;; Print # of increases (RCX) as int with C printf()
        ;;   Using SYSV amd64 ABI
        xor rbx, rbx
        xor rax, rax            ; AL = # of vector arguments (0)
        lea rdi, [format_str]   ; 1st argument
        mov rsi, rcx            ; 2nd argument
        push rbx                ; 16byte align stack by pushing 8byte register before call
        call printf
        pop rbx                 ; 16byte align stack by popping 8byte register after call

        ret

segment .data


segment .rodata
format_str: db "%d",10,0

forward_str: db "forward"
.len equ $ - forward_str

up_str: db "up"
.len equ $ - up_str

down_str: db "down"
.len equ $ - down_str

%include "input.asm"
;%include "test_input.asm"
