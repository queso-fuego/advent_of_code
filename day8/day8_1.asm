;;;
;;; FreeBSD x86_64 asm, used with nasm
;;; AOC 2021 Day8 part 1
;;;
extern printf

global main

segment .text
main:
    ;; Number - # of segments:
    ;; 0 - 6
    ;; 1 - 2
    ;; 2 - 5
    ;; 3 - 5
    ;; 4 - 4
    ;; 5 - 5
    ;; 6 - 6
    ;; 7 - 3
    ;; 8 - 7
    ;; 9 - 6
    ;; Numbers with unique # of segments: 1,4,7,8
    
    cld                 ; String ops will increment RSI/RDI

    xor rax, rax        ; Temp
    xor r9, r9          ; Overall answer count

    lea rsi, [data]
    outer_loop:
        cmp rsi, EOF
        jge done

        ;; Read through next 10 words
        mov byte [i], 0
        .inner_loop_1:
            .get_word:
                lodsb
                cmp al, ' '
            jne .get_word

            inc byte [i] 
            cmp byte [i], 10
        jl .inner_loop_1

        lodsb               ; Skip pipe '|'
        lodsb               ; Skip space after pipe

        ;; Read next 4 words and determine what numbers they are
        mov byte [i], 0
        .inner_loop_2:
            ;; If number is 1/4/7/8 increment count
            xor r8, r8          ; Length of word
            .get_word_2:
                inc r8
                lodsb
                cmp al, ' '
            jne .get_word_2

            dec r8              ; Counted 1 too many due to space

            cmp r8, 2           ; 1
            jne .check_7
            inc r9

            .check_7:
            cmp r8, 3           ; 7
            jne .check_4
            inc r9

            .check_4:
            cmp r8, 4           ; 4
            jne .check_8
            inc r9

            .check_8:
            cmp r8, 7           ; 8
            jne .next
            inc r9

            .next:
            inc byte [i] 
            cmp byte [i], 4
        jl .inner_loop_2
    jmp outer_loop

    done:
        ;; Total count is the answer
        mov rcx, r9

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
i: db 0

segment .rodata
format_str: db "%lld",10,0       

%include "input.asm"
;%include "test_input.asm"
