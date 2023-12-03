;;;
;;; FreeBSD x86_64 asm, used with nasm
;;; AOC 2021 Day4 part 2
;;;
%define FALSE 0     ; DIY boolean
%define TRUE 1
;%define MAX_BOARDS 3   ; Test input
%define MAX_BOARDS 100

extern printf       ; C printf()

global main         ; Default entry point for c compiler linked programs

segment .text
main:
    lea rsi, [bingo_nums]   ; Input bingo numbers
    xor rcx, rcx            ; Counter
    xor r13, r13            ; Winning board array counter
    xor r15, r15            ; Save AL value
    xor r12, r12            ; Save last winning board bingo number
    cld                     ; String ops will increment RSI/RDI
    
    draw_next_number:
        cmp rsi, boards         ; Boards are stored after bingo nums
        je add_winning_numbers  ; Reached end of input, stop
        lodsb                   ; Else AL = next bingo number
        mov r15b, al            ; Store scan value for later

        ;; Mark each board where the number matches the drawn number
        lea rdi, [boards]          
        mov r14, -1             ; R14 = current board counter
        check_next_board:
            cmp rdi, EOF
            jge draw_next_number

            mov cl, 25
            .scan_loop:
                cmp al, [rdi]
                je .found
                inc rdi
            loop .scan_loop

            .found:
                inc r14                 ; If reached end of boards start over with next number
                jecxz check_next_board ; Checked whole board, did not find number
                ;; Skip this board if already won
                lea rbx, [has_won]
                add rbx, r14
                cmp byte [rbx], TRUE
                jne .set_marked_byte    ; Not won yet, mark byte in board

                ;; Else board already won 
                add rdi, rcx            ; Set rdi to start of next board
                mov al, r15b            ; Restore value to scan on next board
                jmp check_next_board    ; Board already won, move on

            .set_marked_byte:
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
        jmp check_next_board

    done:
        ;; Add board number to winning boards arrays
        lea rbx, [has_won]
        add rbx, r14
        mov byte [rbx], TRUE    ; Board has now won
        mov r12, r15            ; Save last winning bingo number

        lea rbx, [winning_boards]
        add rbx, r13            ; Next empty slot
        mov [rbx], r14b         ; Add board number to slot
        inc r13
        cmp r13, MAX_BOARDS     ; If added last board, no more can win, go on
        je add_winning_numbers  
        ;; Else check other boards for same number
        add rdi, r9     ; RDI points to start of next board
        mov al, r15b    ; Restore value to scan on next board
        jmp check_next_board

    add_winning_numbers:
    ;; Get last won board
    xor rax, rax
    xor rcx, rcx
    dec r13
    lea rbx, [winning_boards]
    add rbx, r13
    mov al, [rbx]           ; AL = last won board #

    mov cl, 25
    imul rax, rcx           ; Board # * 25 = offset into boards array, in bytes
    lea rdi, [boards]
    add rdi, rax            ; RDI points to start of board
    lea r11, [marked_boards]
    add r11, rax            ; R11 points to start of board in marked boards array
    
    ;; Add up all unmarked numbers on the last winning board
    xor rbx, rbx            ; Sum of unmarked numbers
    xor rdx, rdx            ; Temp
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
    xor rax, rax
    mov rax, r12
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
marked_boards: times MAX_BOARDS*25 db 0    ; Puzzle input
has_won: times MAX_BOARDS db 0             ; Array of "bools" for winning boards
winning_boards: times MAX_BOARDS db 0      ; Array of winning board numbers

segment .rodata
format_str: db "%d",10,0       

%include "input.asm"
;%include "test_input.asm"
