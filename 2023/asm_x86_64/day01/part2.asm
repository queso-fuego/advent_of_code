format ELF64 dynamic 3
entry main

include '../linux.inc'
include '../helper_lib.inc'

segment executable 
main: 
cld     ; String ops will increment RDI/RSI

;; Run code for input files
write_string test_file
lea r8, [test_file]
call part2

write_string input_file
lea r8, [input_file]
call part2

;; End program
end_pgm:
exit 42

;; -----------------------------------
;; Main logic
;; -----------------------------------
part2:
;; Open input file
open r8, O_RDONLY
mov [fd], eax

;; Get size of file for buffer
lseek [fd], 0, SEEK_END
mov [file_len], rax
lseek [fd], 0, SEEK_SET ; Rewind file for reading

;; Map file in memory
mmap NULL, [file_len], PROT_READ, MAP_SHARED, [fd], 0
mov [file_addr], rax

;; Close file
close [fd]

;; Initialize work variables
mov qword [sum], 0
mov byte [first_digit], 0
mov byte [last_digit], 0

mov rcx, 5
lea rdi, [num_window]
xor rax,rax
rep stosb

lea r9, [num_window]    ; R9 = start of window
mov r10, r9             ; R10 = end of window, up to R9+4

;; Read file buffer
mov rsi, [file_addr]
xor rax, rax            ; RAX = next digit
next_char:
    lodsb
    cmp al, 0           ; EOF
    je done_reading
    cmp al, 0xA         ; Newline
    je .end_of_line
    cmp al, '0'         ; Check for number, '0' <= al <= '9'
    jl .found_char
    cmp al, '9'
    jg .found_char

    ;; Found digit
    .first_digit:
    cmp byte [first_digit], 0   ; Already got first digit in line?
    jne .last_digit             ; Yes, only set last digit
    mov [first_digit], al       ; No, set 1st digit first

    .last_digit:
    mov [last_digit], al        ; Overwrite with new last digit
    jmp next_char

    .found_char:
    ;; Add char to sliding window buffer
    ; Replace window chars between r9 and r10 with pos = pos+1
    cmp byte [r10], 0       ; Has full window been filled yet?
    je .set_window_char     ; No, go on

    mov rbx, r9
    .update_window:
    mov cl, [rbx+1]
    mov [rbx], cl
    inc rbx
    cmp rbx, r10
    jne .update_window

    .set_window_char:
    mov [r10], al  

    ; Increment end of buffer if not full yet
    mov rbx, r10
    sub rbx, r9
    cmp rbx, 4      ; End pointer at end of window?
    je .cmp_strings ; Yes, go on 
    inc r10         ; No, increment window end pointer

    .cmp_strings:
    ; Compare window (between r9-r10) against number strings.
    ;  Need to compare all ranges between r9 and r10:
    ;  r9-10, r9+1 - r10, r9+2 - r10. There are no 1 or 2 char strings,
    ;  so can end there if none found. Ex:
    ; for (i = 0; i < 9; i++) {
    ;     for (j = 0; j < 3; j++) {
    ;         if (!strncmp(num_window+j, number_strings[i], 5-j)) {
    ;             // Found match; Convert i from int to char, use as first/last digit.
    ;             goto done;
    ;         }
    ;     }
    ; }
    ; done:
    ; <digit> = i + '0'+1; // Convert int -> char, 1-based
    ; ...
    lea rdi, [number_strings]
    xor r11, r11        ; i
    .outer_loop:
        xor r12, r12    ; j
        .inner_loop:
            mov rbx, r9
            add rbx, r12        ; str1 = num_window + j

            imul rdx, r11, 6    ; Each string is 6 bytes, offset into array
            add rdx, rdi        ; str2 = number_strings[i]

            mov rcx, 5
            sub rcx, r12        ; len = 5 - j
            call strncmp
            test rax, rax       ; Found match? 1 = true, 0 = false
            jnz .found_match    ; Yes, get digit

            inc r12             ; No, go on; j++
            cmp r12, 3          ; j < 3
        jne .inner_loop
        inc r11                 ; i++
        cmp r11, 9              ; i < 9
    jne .outer_loop

    jmp next_char   ; Ended loop without a match

    .found_match:
    add r11, '0'+1  ; Get found digit as char, 1-based so need to add 1 
    mov rax, r11
    jmp .first_digit

    .end_of_line:
    ;; Add both digits in line together for final number 
    sub byte [first_digit], '0' ; Convert char -> int
    sub byte [last_digit], '0'  ; Convert char -> int

    ;; Add to total sum: sum += 1st digit * 10 + last digit
    mov al, [first_digit]   
    imul rax, rax, 10           
    add al, [last_digit]

    add [sum], rax

    ;; Clear digits for next line
    mov byte [first_digit], 0
    mov byte [last_digit], 0
    mov rcx, 5
    lea rdi, [num_window]
    xor rax,rax
    rep stosb
    lea r10, [num_window]    ; R10 = end of window
jmp next_char

done_reading:
;; Unmap file
munmap [file_addr], [file_len]

;; Print results
write_string answer_string
mov rax, [sum]      ; Number to print
call print_number
write_string newline

ret

;; -----------------------------------
;; Read only memory 
;; -----------------------------------
segment readable 
make_string answer_string, ' answer: '

make_string test_file, 'test2.txt',0
make_string input_file, 'input.txt',0

;; All of these are 6 bytes in length, to act as an array like
;;   char[6][9] (nice)
number_strings:
one_string   db 'one',0,0,0
two_string   db 'two',0,0,0
three_string db 'three',0
four_string  db 'four',0,0
five_string  db 'five',0,0
six_string   db 'six',0,0,0
seven_string db 'seven',0
eight_string db 'eight',0
nine_string  db 'nine',0,0

;; -----------------------------------
;; Read write memory
;; -----------------------------------
segment readable writeable
fd dd 0
file_len dq 0
file_addr dq 0

first_digit db 0
last_digit db 0
sum dq 0

num_window: times 5 db 0    ; Longest number string is 5 characters

