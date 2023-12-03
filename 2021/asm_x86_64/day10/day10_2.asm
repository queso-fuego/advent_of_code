;;;
;;; FreeBSD x86_64 asm, used with nasm
;;; AOC 2021 Day10 part 2
;;;
%define LINE_END 10     ; Newline, \n
%define FALSE 0
%define TRUE 1

extern printf

global main

segment .text
main:
    cld                 ; String ops will increment RSI/RDI
    xor rbx, rbx
    xor rcx, rcx
    mov r10, scores     ; Scores array index

    mov rsi, data  
    next_line:
        cmp byte [legal], TRUE
        jne .clear_stack

        ;; Legal incomplete line; Pop and add up stack values
        mov r11, rdi
        sub r11, bracket_stack  ; Get offset into stack, # of elements
        xor r9, r9          ; Current completion score
        .add_stack_loop:
            cmp r11, 0      ; End of stack?
            je .add_to_scores ; Yes, go on
            dec r11
            dec rdi         ; Else "pop" stack value
            mov al, [rdi]

            imul r9, r9, 5  ; Multiply current score by 5 before adding

            cmp al, ')'
            jne .add_sqbr
            inc r9
            jmp .add_stack_loop

            .add_sqbr:
            cmp al, ']'
            jne .add_crbr
            inc r9
            inc r9
            jmp .add_stack_loop

            .add_crbr:
            cmp al, '}'
            jne .add_anbr
            add r9, 3
            jmp .add_stack_loop

            .add_anbr:
            add r9, 4
            jmp .add_stack_loop

        ;; Add to scores array
        .add_to_scores:
            mov [r10], r9
            add r10, 8              ; Next index in scores array
            inc byte [num_scores]   ; Number of scores += 1

        ;; Clear stack array
        .clear_stack:
        xor rcx, rcx
        mov cl, 200
        xor rax, rax
        mov rdi, bracket_stack
        rep stosb
        mov rdi, bracket_stack

        mov byte [legal], TRUE

        next_char:
            cmp rsi, EOF
            jge done       

            lodsb
            cmp al, LINE_END
            je next_line

            cmp al, '('
            jne .check_sqbr
            mov byte [rdi], ')'
            inc rdi
            jmp next_char

            .check_sqbr:
            cmp al, '['
            jne .check_crbr
            mov byte [rdi], ']'
            inc rdi
            jmp next_char

            .check_crbr:
            cmp al, '{'
            jne .check_anbr
            mov byte [rdi], '}'
            inc rdi
            jmp next_char

            .check_anbr:
            cmp al, '<'
            jne .check_legal
            mov byte [rdi], '>'
            inc rdi
            jmp next_char

            .check_legal:
            ;; "Pop" last char from stack
            dec rdi
            mov bl, [rdi]
            mov byte [rdi], 0
            cmp al, bl
            je next_char

            .illegal:
            mov byte [legal], FALSE

            .read_rest_of_line:
            lodsb
            cmp al, LINE_END
            jne .read_rest_of_line
            jmp next_line

    done:
        ;; Sort scores - Bubble sort
        ;; while (swapped == true) {
        ;;     swapped = false;
        ;;     for (int i = 0; i < num_scores; i++) {
        ;;         if (scores[i] > scores[i+1]) {  
        ;;             temp = scores[i+1];
        ;;             scores[i+1] = scores[i];
        ;;             scores[i] = temp;
        ;;             swapped = true;
        ;;         }
        ;;     }
        ;; }
        mov byte [swapped], TRUE
        .while_swapped:
            mov byte [swapped], FALSE
            mov rdi, scores
            mov rbx, 1
            .for_loop:
                mov rax, [rdi]
                cmp rax, [rdi+8]
                jle .next

                ;; Swap values
                mov rdx, [rdi+8]    ; RDX = temp = scores[i+1]
                mov [rdi+8], rax    ; scores[i+1] = scores[i]
                mov [rdi], rdx      ; scores[i] = scores[i+1]
                mov byte [swapped], TRUE

                .next:
                add rdi, 8          ; Next score
                inc rbx
                cmp bl, [num_scores]
            jl .for_loop
            cmp byte [swapped], TRUE
        je .while_swapped

        ;; Get Middle score (guaranteed to always have odd # of scores)
        .get_middle_score:
        xor r8, r8
        mov r8b, [num_scores]
        shr r8b, 1              ; # of scores / 2
        imul r8, r8, 8          ; Multiply by 8 to get quadword offset
        add r8, scores          ; Offset into scroes for middle score
        mov rcx, [r8]           ; RCX = middle score

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
bracket_stack: times 200 db 0
scores: times 110 dq 0
legal: db FALSE
num_scores: db 0
swapped: db FALSE

segment .rodata
format_str: db "%lld",10,0       

%include "input.asm"
;%include "test_input.asm"
