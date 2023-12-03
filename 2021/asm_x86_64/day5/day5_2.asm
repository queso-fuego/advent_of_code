;;;
;;; FreeBSD x86_64 asm, used with nasm
;;; AOC 2021 Day5 part 2
;;;
%define FALSE 0         ; Booleans
%define TRUE 1
;%define MAX_VENTS 10    ; Test input
%define MAX_VENTS 1000  ; Puzzle input

extern printf

global main

segment .text
main:
    lea rsi, [data]     ; Input 
    xor rax, rax        ; Temp
    xor rbx, rbx        ; X value
    xor rdx, rdx        ; Y value
    xor r8, r8          ; X value
    xor r9, r9          ; Y value
    cld                 ; String ops will increment RSI/RDI
    
    read_loop:
        cmp rsi, EOF
        jge done_reading
        ;; Get next X,Y values
        lodsw           ; AX = 1st X
        mov bx, ax
        lodsw           ; AX = 1st Y
        mov dx, ax
        lodsd           ; Skip arrow "->"  ;; DEBUGGING
        lodsw           ; AX = 2nd X
        mov r8w, ax
        lodsw           ; AX = 2nd Y
        mov r9w, ax

        ;; Check type of line: horizontal, vertical, diagonal
        cmp bx, r8w     ; Check if Xs are equal
        je .check_y     ; Xs are equal

        .x_changed:     ; Else Xs are different
            cmp dx, r9w
            jne .diagonal       ; X and Y are different (diagonal)
            jmp .horizontal     ; Else Xs different & Ys equal (horizontal)

        .check_y:
            cmp dx, r9w     ; Check if Ys are equal
            je read_loop    ; Xs and Ys are equal, same point?, skip
            jmp .vertical   ; Else Xs equal & Ys different (vertical)

        ;; If horizontal, loop over Xs
        .horizontal:
            ;; Reverse Xs if going backwards
            cmp bx, r8w             ; 1st X > 2nd X?
            jle .horizontal_loop    ; No, go on

            .reverse_x:             ; Yes, going backwards, switch
                xchg bx, r8w

            .horizontal_loop:
                cmp bx, r8w             ; Reached 2nd X?
                jg read_loop            ; Yes, past end of line, go on
                call increment_vent
                inc bx                  ; Next X value
                jmp .horizontal_loop

        ;; If vertical, loop over Ys
        .vertical:
            ;; Reverse Ys if going up
            cmp dx, r9w             ; 1st Y > 2nd Y?
            jle .vertical_loop      ; No, go on

            .reverse_y:             ; Yes, going up, switch
                xchg dx, r9w        

            .vertical_loop:
                cmp dx, r9w             ; Reached 2nd Y?
                jg read_loop            ; Yes, past end of line, go on
                call increment_vent     ; No, increment vent line #
                inc dx                  ; Next Y value
                jmp .vertical_loop

        ;; If diagonal, loop over Xs & Ys
        .diagonal:
            cmp dx, r9w             ; 1st Y > 2nd Y?
            jle .check_diag_x       ; No, go on

            .diag_reverse_y:        ; Yes, going up, switch points (Xs & Ys)
                xchg bx, r8w        
                xchg dx, r9w        

            .check_diag_x:
                ;; Is 1st X less than (to the left of) 2nd X?
                ;;   or greater than (to the right of) 2nd X?
                cmp bx, r8w         
                jle .diagonal_xright_loop    ; X2 > X1, going right-down

            .diagonal_xleft_loop:
                ;; Going left-down, decrement X and increment Y
                cmp bx, r8w
                jl read_loop        ; X1 < X2, passed end of line
                cmp dx, r9w
                jg read_loop        ; Y1 > Y2, passed end of line

                call increment_vent ; Increment vent line #

                dec bx
                inc dx
            jmp .diagonal_xleft_loop

            .diagonal_xright_loop:
                ;; Going right-down, increment X and increment Y
                cmp bx, r8w
                jg read_loop        ; X1 > X2, passed end of line
                cmp dx, r9w
                jg read_loop        ; Y1 > Y2, passed end of line

                call increment_vent ; Increment vent line #

                inc bx
                inc dx
            jmp .diagonal_xright_loop

    done_reading:
        ;; Loop through all vents, count up how many spaces are 2 or more
        mov rbx, -1         ; Counter
        xor rcx, rcx        ; Counter
        lea r10, [vents]
        .count_vents_loop:
            inc rbx
            cmp rbx, MAX_VENTS*MAX_VENTS    ; Done reading?
            je print_answer

            cmp word [r10], 2
            jl .next
            inc rcx                 ; Else vent # is 2+, add to count
            .next:
                inc r10
                inc r10             ; Add 2 bytes for word values
                jmp .count_vents_loop

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

;; Subroutine to increment byte in 2D vents array
;; BL = X, DL = Y, MAX_VENTS = Width
increment_vent:
    mov r10, rdx                ; R10 = Y in bytes
    shl r10, 1                  ; R10 = Y in words
    imul r10, r10, MAX_VENTS    ; R10 = Y *= Width (words are 2 bytes!)
    mov r11, rbx                ; R11 = width in bytes
    shl r11, 1                  ; R11 = width in words
    add r10, r11                ; Y *= Width + X 
    add r10, vents              ; Offset into vents
    inc word [r10]              ; Increment this word

    ret

segment .data
vents: times MAX_VENTS*MAX_VENTS dw 0   ; Puzzle input

segment .rodata
format_str: db "%d",10,0       

%include "input.asm"
;%include "test_input.asm"
