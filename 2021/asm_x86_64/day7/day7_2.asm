;;;
;;; FreeBSD x86_64 asm, used with nasm
;;; AOC 2021 Day7 part 2
;;;
%define MAX_POSITIONS 2000

extern printf

global main

segment .text
main:
    cld                 ; String ops will increment RSI/RDI

    ;; Read input into array
    xor rax, rax        ; Temp
    xor r9, r9          ; Total positions count
    lea rsi, [data]     ; Input 
    lea rdi, [positions]
    read_loop:
        cmp rsi, EOF
        jge get_differences
        movsw           ; [RDI] = [RSI], add RSI,2 & add RDI,2
        inc r9          ; Num of total positions
    jmp read_loop

    ;; Get difference for all positions to any given 1 position
    ;; (this would be at least n^2 naively, think of better way?)
    get_differences:
        lea rsi, [positions] 
        mov dword [i], 0         ; Will loop through all input
        difference_loop:
            ;; Next position to compare all positions against
            lodsw                ; AX = [RSI], add RSI,2
            xor r8, r8           ; Running total
            lea rdi, [positions] 
            mov dword [j], 0     ; Loop through all input
            .loop:
                xor rbx, rbx
                xor rdx, rdx
                mov bx, ax
                sub bx, [rdi]
                mov dx, bx       ; Get absolute value of difference:
                neg dx           ; Negate, dx = -bx
                cmp bx, 0
                cmovl bx, dx     ; If bx < 0, bx = dx

                ;; Difference needs to be summed by 1 to itself, or
                ;; 1+2+3+...+N
                ;; This is an arithmetic progression by 1, which is
                ;; N(N+1)/2 where N = current difference
                mov r10, rbx    ; rbx = difference = N
                inc r10         ; N+1
                imul r10, rbx   ; N+1 *= N (N * N+1)
                shr r10, 1      ; Divide by 2, N(N+1)/2

                add r8, r10      ; Running total += abs(difference)

                inc rdi          ; Go to next position
                inc rdi
                inc dword [j]    ; j++
                cmp dword [j], r9d
            jl .loop

            ;; Get minimum difference total
            cmp r8, [lowest_sum]   ; Current sum < lowest?
            jae .after             ; No, go on (unsigned comparison)
            mov [lowest_sum], r8   ; Yes, set lowest = current sum

            .after:
            inc dword [i]           ; i++
            cmp dword [i], r9d
        jl difference_loop

    ;; The least cost (lowest number of all differences summed up)
    ;; is the answer
    mov rcx, [lowest_sum]  

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
positions: times MAX_POSITIONS dw 0 ; Array for all puzzle input
curr_pos: dw 0                      ; Current position to compare
lowest_sum: dq 0xFFFFFFFFFFFFFFFF   ; Default to max unsigned 64bit number
i: dd 0                             ; Index
j: dd 0                             ; Index

segment .rodata
format_str: db "%lld",10,0       

%include "input.asm"
;%include "test_input.asm"
