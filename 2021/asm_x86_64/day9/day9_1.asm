;;;
;;; FreeBSD x86_64 asm, used with nasm
;;; AOC 2021 Day9 part 1
;;;
%define LINE_END ' '
;%define LINE_LEN 10     ; Test input
%define LINE_LEN 100     ; Puzzle input
%define FALSE 0
%define TRUE 1

extern printf

global main

segment .text
main:
    cld                 ; String ops will increment RSI/RDI

    xor r8, r8          ; Sum of all risk levels of lowest points
    xor rax, rax        ; Temp

    lea rsi, [data]     
    next_char:
        lodsb   
        cmp rsi, EOF    ; At EOF?
        jae done
        cmp al, LINE_END
        je .end_of_line
        inc qword [x]       ; Next X position in line

        ;; Compare current X,Y number to its cardinal neighbors
        ;;   Up/Down/Left/Right:
        ;; Up
        .up:
        cmp qword [y], 0    ; On 1st line?
        je .down            ; Yes, can't compare above
        cmp al, byte [rsi-2-LINE_LEN]  ; Current char lower than 1 line up?
        jge next_char       ; No, skip this char

        ;; Down
        .down:
        cmp rsi, EOF-(LINE_LEN) ; Next line past EOF?
        jae .left               ; Yes, skip checking down
        cmp al, byte [rsi+LINE_LEN]  ; Current char lower than 1 line down?
        jge next_char           ; No, skip this char

        ;; Left
        .left:
        cmp qword [x], 0    ; At start of line?
        je .right           ; Yes, can't compare left
        cmp al, byte [rsi-2]  ; Current char lower than its left?
        jge next_char       ; No, skip this char

        ;; Right
        .right:
        cmp qword [x], LINE_LEN-1   ; At end of line?
        je .add_risk_level          ; Yes, go on, can't compare right
        cmp al, byte [rsi]          ; Current char lower than its right?
        jge next_char               ; No, skip this char

        ;; Current X,Y number is lower than all its neighbors,
        ;;  add 1 to it for the risk level, and add that number 
        ;;  to overall sum
        .add_risk_level:
        sub al, '0'-1   ; Convert char -> int + 1 = risk level
        add r8, rax     ; Add to final answer
        jmp next_char

        .end_of_line:
        mov qword [x], -1   ; Set X,Y values for next line
        inc qword [y]
    jmp next_char

    done:
        ;; Answer is sum of all risk levels of all low points
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
x: dq -1
y: dq 0

segment .rodata
format_str: db "%lld",10,0       

%include "input.asm"
;%include "test_input.asm"
