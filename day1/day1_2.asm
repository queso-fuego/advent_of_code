;;;
;;; FreeBSD x86_64 asm, used with nasm
;;; AOC 2021 Day1 part 2
;;;
bits 64
%define SYS_WRITE 4
%define SYS_EXIT 1
%define STDOUT 1

global _start

segment .text
_start:
    lea rsi, [data]         ; Pointer to input
    xor rax, rax            ; Temp value
    xor rcx, rcx            ; Counter
    cld                     ; String ops will increment RSI/RDI

    ;; Only need to compare every 1st number to every 4th number
    ;;   since 1+2+3 & 2+3+4 share the sum 2+3. In this case the 
    ;;   only thing that matters is if 4 > 1
    .depth_loop:
        lodsw                   ; AX = 1st number of data, RSI points to 2nd number
        cmp word [rsi+4], 0     ; 4th number, EOF?
        je .done_reading

        cmp word [rsi+4], ax    ; is 4th number > 1st number?
        jle .depth_loop
        inc rcx                 ; # of increases
    jmp .depth_loop

    .done_reading:
        ;; Convert # of increases from int to string
        lea rdi, [num_increases]
        mov rax, rcx                ; RAX = # of increases
        mov rbx, 10
        xor rcx, rcx                ; length of number
        xor rdx, rdx
        .convert_loop:
            xor dl, dl              ; Zero out digit
            cmp al, 0
            je .reverse

            div rbx                 ; RDX:RAX / 10, RAX = quotient, RDX = remainder
            xchg rax, rdx           ; Swap RAX and RDX; AL = digit
            add al, '0'             ; Convert int -> ascii char
            stosb                   ; mov [RDI], al & inc RDI; Store char digit
            inc cl                  ; Increment string length 
            xchg rax, rdx           ; Swap RAX and RDX back
        jmp .convert_loop

        .reverse:
            mov [num_increases_len], cl ; Store length of number string
            lea rax, [num_increases]    ; Start pointer
            mov rbx, rax
            add rbx, rcx                
            dec rbx                     ; End pointer (start + length - 1)
            .reverse_loop:
                cmp rax, rbx            ; Did the pointers cross?
                jge .done_reversing

                ;; Reverse string by swapping chars at pointers
                mov cl, [rax]           ; Char at start pointer
                mov dl, [rbx]           ; Char at end pointer
                mov [rbx], cl           ; Char at end = start char
                mov [rax], dl           ; Char at start = end char

                inc rax                 ; Increment start pointer
                dec rbx                 ; Decrement end pointer
            jmp .reverse_loop 

        .done_reversing:
        ;; Write the # of increases
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
