;;;
;;; FreeBSD x86_64 asm, used with nasm
;;; AOC 2021 Day4 part 1
;;;
%define FALSE 0     ; DIY boolean
%define TRUE 1

extern printf

global main

segment .text
main:
    lea rsi, [bingo_nums]   ; Input bingo numbers
    xor rcx, rcx            ; Counter
    cld                     ; String ops will increment RSI/RDI
    
    draw_next_number:
        cmp rsi, boards     ; Boards are stored after bingo nums
        je done             ; Reached end of input, stop
        lodsb               ; Else AL = next bingo number

        ;; Mark each board where the number matches the drawn number
        lea rdi, [boards]          
        .check_next_board:
            cmp rdi, EOF
            jge draw_next_number

            mov cl, 25
            .scan_loop:
                cmp al, [rdi]
                je .found
                inc rdi
            loop .scan_loop

            .found:
                jecxz .check_next_board ; Checked whole board, did not find number

            mov r15b, al            ; Save scan value for next board check 
            lea rax, [marked_boards]
            mov rbx, rdi
            sub rbx, boards         ; Get distance from start of boards
            add rax, rbx            ; Offset the same distance into marked numbers array
            mov byte [rax], TRUE    ; Set byte as marked 

            ;; Check this bingo board's 5byte row and 5 byte column:
            ;; 25 - rcx = offset into current board
            ;; offset / 5 = row
            ;; offset % 5 = column 
            ;;
            ;; subtract column from offset, check up to 5 values for row
            ;; subtract row*5 from offset, check up to 5 values (+5 each
            ;;   time for each row!) for column
            ;; If all 5 are marked in row or column then found winning board
            ;; else check next board
            mov r8, rax         ; Save rax, offset into marked boards
            mov r10, rax        ; ""
            mov r11, rax        ; ""
            mov r9, rcx         ; Save rcx

            xor rax, rax
            xor rdx, rdx

            mov al, 25
            sub al, cl          ; AL = offset into current board
            mov bl, 5
            div bl              ; offset / 5, AL = quotient (row), AH = remainder (column)

            mov dl, ah          ; DL = column 
            sub r8, rdx         ; R8 - column = start of row
            mov cl, 5
            .check_row_loop:
                cmp byte [r8], TRUE
                jne .check_column
                inc r8
            loop .check_row_loop
            
            .check_column:
                jecxz done  ; Found winning row, leave

                xor rdx, rdx    ; Set DH = 0
                mov dl, al      ; DL = row
                imul dx, dx, 5  ; Row *= 5
                sub r10, rdx    ; R10 - row offset = start of column

                mov cl, 5
                .check_column_loop:
                    cmp byte [r10], TRUE
                    jne .check_column_done
                    add r10, 5      ; Go to next row
                loop .check_column_loop

            .check_column_done:
                jecxz done  ; Found winning column, leave

            ;; Not winning board, set rdi to start of next board
            add rdi, r9     ; RDI points to start of next board
            mov al, r15b    ; Restore value to scan on next board
        jmp .check_next_board

    done:
    ;; Add up all unmarked numbers on the winning board
    xor rax, rax
    xor rbx, rbx            ; Sum of unmarked numbers
    xor rdx, rdx
    mov al, 25
    sub rax, r9             ; Offset into current board
    sub r11, rax            ; R11 = start of winning board in marked boards array
    sub rdi, rax            ; RDI = start of winning board in boards array

    mov cl, 25
    .add_unmarked_nums:
        cmp byte [r11], FALSE
        jne .next
        mov dl, byte [rdi]
        add rbx, rdx        ; add amount

        .next:
        inc r11
        inc rdi
    loop .add_unmarked_nums

    ;; Multiply unmarked numbers sum by the last number drawn (winning number)
    dec rsi
    lodsb
    imul rbx, rax   ; Sum *= winning number 
    
    ;; Print integer in RBX using C printf()
    ;;   Using SYSV amd64 ABI
    print_int:
        xor rax, rax            ; AL = # of vector arguments (0)
        lea rdi, [format_str]   ; 1st argument
        mov rsi, rbx            ; 2nd argument
        push rbx                ; 16byte align stack by pushing 8byte register before call
        call printf
        pop rbx                 ; 16byte align stack by popping 8byte register after call

        ret                     ; End program

segment .data
;; Marked/unmarked numbers for each board, using "booleans" (0 = false, 1 = true)
marked_boards: times 100*25 db 0    ; Puzzle input
;marked_boards: times 3*25 db 0      ; Test input

segment .rodata
format_str: db "%d",10,0       

%include "input.asm"
;%include "test_input.asm"
