;;;
;;; FreeBSD x86_64 asm, used with nasm
;;; AOC 2021 Day6 part 1
;;;
;%define MAX_FISH 10000      ; Test input
%define MAX_FISH 10000000    ; Puzzle input; give it 10 million to be safe

extern printf

global main

segment .text
main:
    lea rsi, [data]     ; Input 
    lea rdi, [fish]     ; Lanternfish array
    xor rax, rax        ; Temp
    xor rcx, rcx        ; Counter
    mov r8, 80          ; Day counter
    xor r9, r9          ; Fish counter
    xor r10, r10        ; Current endpoint for array

    cld                 ; String ops will increment RSI/RDI
    
    initial_read_loop:
        cmp rsi, EOF
        jge fish_loop
        movsb                   ; [RDI] = [RSI], increment both
        inc r9                  ; Increment initial count of fish
    jmp initial_read_loop

    next_day:
        dec r8                  ; Day count - 1
        jz done                 ; 80 days passed, end program

    fish_loop:
        xor rcx, rcx        ; Reset array count until endpoint
        mov r10, r9         ; Set new endpoint to fish count
        lea rsi, [fish]     ; Reset RSI to start of array
        .loop:
            inc rcx
            cmp rcx, r10      
            jg next_day     ; Hit endpoint for today, go to next day
            cmp byte [rsi], 0
            je .new_fish

            ;; Decrement this fish's counter
            dec byte [rsi]
            jmp .iter

            ;; Spawn new fish when counter hits 0,
            ;; - New fish is added to fish array, with count 8
            ;; - Counter 0 fish is reset to 6
            ;; - Current fish_count is 1-based, so it is equal to
            ;;     the current end point (first -1 value) in fish array
            .new_fish:
                mov byte [rsi], 6       ; Reset fish counter to 6
                mov rax, r9             ; Current max fish count
                lea rdi, [fish]
                add rdi, rax            ; Offset into fish array
                mov byte [rdi], 8       ; New end point/fish is set to 8
                inc r9                  ; Fish count + 1

            .iter:
                inc rsi     ; Go to next fish
                jmp .loop

    done:
        mov rcx, r9             ; Final amount of fish 

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

segment .data
fish: times MAX_FISH db 0       ; -1 will be end of array

segment .rodata
format_str: db "%d",10,0       

%include "input.asm"
;%include "test_input.asm"
