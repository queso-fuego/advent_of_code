;;;
;;; FreeBSD x86_64 asm, used with nasm
;;; AOC 2021 Day1 part 1
;;;
bits 64
%define SYS_WRITE 4
%define SYS_EXIT 1
%define STDOUT 1

global _start

segment .text
_start:
    lea rsi, [data]
    xor rax, rax            ; Temp value
    xor rcx, rcx            ; Counter
    cld                     ; String ops will increment RSI/RDI

    .depth_loop:
        lodsw               ; AX = 1st number of data
        cmp word [rsi], 0   ; 2nd Number, is it EOF?
        je .done_reading
        
        cmp word [rsi], ax  ; Is 2nd number > 1st number?
        jle .depth_loop
        inc rcx             ; Increment # of increases
    jmp .depth_loop

    .done_reading:
        ;; Convert num of increases from int to string
        lea rdi, [num_increases]
        mov rax, rcx                ; RAX = number of increases
        mov rbx, 10
        xor rcx, rcx                ; length of number
        xor rdx, rdx
        .convert_loop:
            xor dl, dl              ; Zero out digit
            cmp al, 0               ; Done getting digits?
            je .reverse

            div rbx                 ; RDX:RAX / 10, RAX = quotient, RDX = remainder
            xchg rax, rdx           ; Swap RAX and RDX, AL = digit
            add al, '0'             ; Convert int -> ascii char
            stosb                   ; mov [RDI], al & inc RDI
            inc cl                  ; Increment string length 
            xchg rax, rdx           ; Swap RAX and RDX
        jmp .convert_loop

        .reverse:
            mov [num_increases_len], cl ; Store length of number string
            lea rax, [num_increases]
            mov rbx, rax
            add rbx, rcx                
            dec rbx                     ; End pointer
            .reverse_loop:
                cmp rax, rbx
                jge .done_reversing

                ;; Reverse string to print correctly
                mov cl, [rax]           ; Char at start pointer
                mov dl, [rbx]           ; Char at end pointer
                mov [rbx], cl           ; Char at end = start char
                mov [rax], dl           ; Char at start = end char

                inc rax                 ; Increment start pointer
                dec rbx                 ; Decrement end pointer
            jmp .reverse_loop  ; decrement rcx, if RCX = 0 go on, else jump to label

        .done_reversing:
        ;; Write number of increases
        mov rax, SYS_WRITE              ; syscall #
        mov rdi, STDOUT                 ; fd
        lea rsi, [num_increases]        ; address of string
        xor rdx, rdx
        mov dl, [num_increases_len]     ; length of string
        syscall

        ;; Write newline
        mov rax, SYS_WRITE              ; syscall #
        mov rdi, STDOUT                 ; fd
        lea rsi, [newline]              ; address of string
        mov rdx, 1                      ; length of string
        syscall

        ;; Exit 
        mov rax, SYS_EXIT   ; syscall #
        xor rdi, rdi        ; exit code
        syscall

        ret

segment .data
num_increases: times 5 db 0
num_increases_len: db 0
newline: db 10

%include "input.asm"
