;;;
;;; FreeBSD x86_64 asm, used with nasm
;;; AOC 2021 Day8 part 2
;;;
%define FALSE 0
%define TRUE 1

extern printf

global main

segment .text
main:
    cld                 ; String ops will increment RSI/RDI

    xor rax, rax        ; Temp
    xor rcx, rcx        ; Counter
    xor r10, r10        ; Overall answer sum

    lea rsi, [data]
    read_loop:
        cmp rsi, EOF
        jge done

        ;; Clear words array
        lea rdi, [words]
        xor rax, rax
        mov cl, 10
        rep stosq

        ;; Read through next 10 words
        lea rdi, [words]
        mov byte [i], 0
        .store_words_loop:
            xor rcx, rcx
            .get_word:
                lodsb
                cmp al, ' '
                je .sort_word
                stosb           ; Store letter at current word
                inc rcx         ; Increment word length 
            jmp .get_word

            .sort_word:
            sub rdi, rcx        ; Move to start of word
            call sort_word

            add rdi, 8          ; Next word in array
            inc byte [i]        ; i++
            cmp byte [i], 10    ; At end of words?
        jl .store_words_loop

        lodsw                   ; Skip pipe '|' and space after pipe

        ;; Determine which word corresponds with which number,
        ;;   and which letter with which segment.
        ;; Clear temp array
        lea rdi, [temp]
        xor rax, rax            
        mov cl, 10
        rep stosq

        lea rdi, [words] 
        mov byte [i], 0
        get_1_7_4_8:
            call strlen        ; RCX = string length

            cmp cl, 2
            jne .check_7
            ;; Found 1
            mov rax, [rdi]
            mov [temp+1*8], rax         ; Store word for 1 in temp array

            .check_7:
            cmp cl, 3
            jne .check_4
            ;; Found 7
            mov rax, [rdi]
            mov [temp+7*8], rax         ; Store word for 7 in temp array

            .check_4:
            cmp cl, 4
            jne .check_8
            ;; Found 4
            mov rax, [rdi]
            mov [temp+4*8], rax         ; Store word for 4 in temp array

            .check_8:
            cmp cl, 7
            jne .next
            ;; Found 8
            mov rax, [rdi]
            mov [temp+8*8], rax         ; Store word for 8 in temp array

            .next:
            add rdi, 8                  ; Next word in array
            inc byte [i]
            cmp byte [i], 10
        jl get_1_7_4_8

        ;; Got 1,4,7,8
        ;; Get 6, only number with word length 6 that doesn't 
        ;;   have all segments of 1
        get_6:
            lea rdi, [words]
            .loop:
                call strlen    ; RCX = length
                cmp cl, 6
                jne .next_word

                ;; Check if all segments of 1 are in current string
                ;; If they aren't, then we have found 6

                ; RDI is pointing to string that may be 6
                lea rdx, [temp+1*8]     ; String to check characters with
                call check_contains_all_characters
                cmp al, TRUE
                je .next_word       ; Segments for 1 are in this word, skip

                ;; Else 1 does not match, found 6
                mov rax, [rdi]      ; Word for 6
                mov [temp+6*8], rax ; Store word for 6 in temp array
                jmp get_5           ; Go on

                .next_word:
                add rdi, 8          ; Next word in array
            jmp .loop

        ;; Got 1,4,6,7,8
        ;; Get 5, word length 5 and matches all segments of 6
        get_5:
            lea rdi, [words]
            .loop:
                call strlen    ; RCX = length
                cmp cl, 5
                jne .next_word
                
                ;; Check if all segments of 5 are in 6
                mov rdx, rdi            ; RDX = maybe word for 5
                push rdi
                lea rdi, [temp+6*8]     ; RDI = word for 6
                call check_contains_all_characters
                pop rdi
                cmp al, TRUE             
                jne .next_word      ; Segments for 5 are not in this word

                ;; Else 6 does match, found 5
                mov rax, [rdi]
                mov [temp+5*8], rax ; Store word for 5 in temp array
                jmp get_0           ; Go on

                .next_word:
                add rdi, 8          ; Next word in array
            jmp .loop
            
        ;; Got 1,4,5,6,7,8
        ;; Get 0, only number with word length 6 that doesn't
        ;;   have all segments of 5
        get_0:
            lea rdi, [words]
            mov rbx, [temp+5*8]         ; RBX = word for 5
            .loop:
                call strlen    ; RCX = length
                cmp cl, 6
                jne .next_word

                mov rax, [rdi]
                cmp rax, [temp+6*8]
                je .next_word           ; Found 6, not 0
                
                ;; Check if segments of 5 match
                ;; RDI is pointing to maybe word 0
                lea rdx, [temp+5*8] ; RDX points to word 5
                call check_contains_all_characters
                cmp al, TRUE        ; Do all chars in 5 match rdi string?
                je .next_word       ; Yes, found 9, not 0

                ;; Else 5 does not match, found 0
                mov rax, [rdi]      ; Word for 0
                mov [temp], rax     ; Store word for 0 in temp array
                jmp get_9           ; Go on

                .next_word:
                add rdi, 8          ; Next word in array
            jmp .loop

        ;; Got 0,1,4,5,6,7,8
        ;; Get 9, word length 6 not found yet
        get_9:
            lea rdi, [words]
            .loop:
                call strlen    ; RCX = length
                cmp cl, 6
                jne .next_word
                
                ;; Check if matches 0 or 6
                mov rax, [rdi]
                cmp rax, [temp]
                je .next_word           ; Found 0, not 9

                cmp rax, [temp+6*8]
                je .next_word           ; Found 6, not 9

                ;; Else length is 6 and is not 0 or 6, 
                ;;   found 9
                mov [temp+9*8], rax ; Store word for 9 in temp array
                jmp get_3           ; Go on

                .next_word:
                add rdi, 8          ; Next word in array
            jmp .loop

        ;; Got 0,1,4,5,6,7,8,9
        ;; Get 3, word length 5 and matches all segments of 9
        get_3:
            lea rdi, [words]
            .loop:
                call strlen    ; RCX = length
                cmp cl, 5
                jne .next_word

                mov rax, [rdi]
                cmp rax, [temp+5*8]     
                je .next_word           ; Found 5, not 3

                ;; Check if segments of 9 match 
                push rdi
                mov rdx, rdi        ; String to check its chars in rdi str
                lea rdi, [temp+9*8] ; string to check against
                call check_contains_all_characters
                pop rdi

                cmp al, TRUE        ; Are all chars in 3 in 9?
                jne .next_word      ; Segments for 3 are not in this word

                ;; Else 9 does match, found 3
                mov rax, [rdi]
                mov [temp+3*8], rax ; Store word for 3 in temp array
                jmp get_2           ; Go on

                .next_word:
                add rdi, 8          ; Next word in array
            jmp .loop

        ;; Got 0,1,3,4,5,6,7,8,9
        ;; Get 2, last number with word length 5 and not found yet
        get_2:
            lea rdi, [words]
            .loop:
                call strlen    ; RCX = length
                cmp cl, 5
                jne .next_word
                
                ;; Check if matches 3 or 5
                mov rax, [rdi]
                cmp rax, [temp+3*8]
                je .next_word           ; Found 3, not 2

                cmp rax, [temp+5*8]
                je .next_word           ; Found 5, not 2

                ;; Else length is 5 and is not 3 or 5, 
                ;;   found 2
                mov [temp+2*8], rax ; Store word for 2 in temp array
                jmp get_output      ; Go on

                .next_word:
                add rdi, 8          ; Next word in array
            jmp .loop

        ;; Got All 10 digit words
        ;; Get the 4 output words, convert to 4-digit number, add to sum
        get_output:
            mov byte [i], 0
            xor r9, r9              ; Temp integer for output
            .next_word_loop:
                xor rax, rax
                xor rcx, rcx
                lea rdi, [output_word]
                mov [rdi], rax      ; Clear output word
                .get_word:
                    lodsb
                    cmp al, ' '
                    je .sort_word
                    stosb           ; Store letter at word
                    inc rcx         ; Increment word length 
                jmp .get_word

                .sort_word:
                sub rdi, rcx        ; Move to start of word
                call sort_word

                ;; Convert word to correct number word
                lea rdi, [temp]             ; Words array for this input line
                mov rax, [output_word]
                mov byte [j], 0
                .find_number_loop:
                    cmp rax, [rdi]
                    jne .check_next_word

                    ;; Found number word, add next digit to temp int
                    imul r9, r9, 10         ; temp *= 10
                    movsx rax, byte [j]     ; J = digit
                    add r9, rax             ; temp + digit
                    jmp .next_output_word

                    .check_next_word:
                    add rdi, 8              ; Next word in words array
                    inc byte [j]
                jmp .find_number_loop

                .next_output_word:
                inc byte [i]        ; i++
                cmp byte [i], 4     ; At end of words?
            jl .next_word_loop

            ;; Add temp int to final sum
            add r10, r9
    jmp read_loop           ; Go on to next line of input 

    done:
        ;; Sum of all output values is the answer
        mov rcx, r10

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

;; Subroutine to get the length of a NULL terminated string
;; Input:
;;   RDI = string address
;; Output:
;;   RCX = string length
strlen:
    push rdi
    xor rcx, rcx    ; RCX = 0
    not rcx         ; RCX = -1, all bits set
    mov al, 0       ; Look for end of word NULL
    repne scasb     ; RCX-1 for each byte including NULL, RCX = -strlen - 2
    not rcx         ; RCX = strlen+1
    dec rcx         ; RCX = strlen
    pop rdi
    ret

;; Subroutine to check if a string contains every character of another
;;   string, but not if it contains a substring
;; E.g. "abde" contains 'b' and 'e', but not 'be'
;; Input:
;;   RDI = NULL terminated string to check within
;;   RDX = NULL terminated string to check characters in
;; Output:
;;   RAX = 1 for all characters in RDI string
;;   RAX = 0 for not all characters in RDI string
check_contains_all_characters:
    xor rax, rax
    .next_rdx_char:
        mov al, [rdx] 
        cmp al, 0
        je .done

        mov r8b, FALSE
        mov rbx, rdi
        .check_loop:
            cmp al, [rbx]
            jne .next_rdi_char

            mov r8b, TRUE   ; Found char

            .next_rdi_char:
            inc rbx
            cmp byte [rbx], 0
        jne .check_loop

        cmp r8b, TRUE
        jne .done           ; Return false

        inc rdx
    jmp .next_rdx_char

    .done:
        mov al, r8b
        ret

;; Subroutine to sort word in ascending order
;; (Bubble sort)
;; Input:
;;   RDI = string address
;;   RCX = string length
sort_word:
    mov byte [swapped], TRUE
    .while_loop:
        mov byte [swapped], FALSE
        mov rbx, rdi
        push rcx            ; String length
        dec rcx             ; Only check up to length-1
        .for_loop:
            mov al, [rbx]
            cmp al, [rbx+1] 
            jle .next_char

            ;; Swap characters to sort
            mov dl, [rbx+1]
            mov [rbx+1], al
            mov [rbx], dl  
            mov byte [swapped], TRUE

            .next_char:
            inc rbx
        loop .for_loop
        pop rcx
        cmp byte [swapped], TRUE
    je .while_loop
    ret

segment .data
i: db 0
j: db 0
words: times 10*8 db 0  ; Input words
temp: times 10*8 db 0   ; Input matched to numbers
swapped: db FALSE
output_word: times 8 db 0   ; 1 of the 4 output words

segment .rodata
format_str: db "%lld",10,0       

%include "input.asm"
;%include "test_input.asm"
