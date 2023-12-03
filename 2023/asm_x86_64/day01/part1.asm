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
call part1

write_string input_file
lea r8, [input_file]
call part1

;; End program
end_pgm:
exit 42

;; -----------------------------------
;; Main logic
;; -----------------------------------
part1:
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

;; Clear work variables
mov qword [sum], 0
mov byte [first_digit], 0
mov byte [last_digit], 0

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
    jl next_char
    cmp al, '9'
    jg next_char

    ;; Found digit
    cmp byte [first_digit], 0   ; Already got first digit in line?
    jne .last_digit             ; Yes, only set last digit
    mov [first_digit], al       ; No, set 1st digit first

    .last_digit:
    mov [last_digit], al        ; Overwrite with new last digit
    jmp next_char

    .end_of_line:
    ;; Add both digits in line together for final number 
    sub byte [first_digit], '0' ; Convert char -> int
    sub byte [last_digit], '0'  ; Convert char -> int

    mov al, [first_digit]       ; RAX = 1st digit * 10 + last digit
    imul rax, rax, 10           
    add al, [last_digit]

    ;; Add to total sum
    add [sum], rax
    xor rax, rax

    ;; Clear digits for next line
    mov byte [first_digit], 0
    mov byte [last_digit], 0
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

make_string test_file, 'test1.txt',0
make_string input_file, 'input.txt',0

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

