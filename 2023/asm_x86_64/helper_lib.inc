;;
;; Helper functions for various tasks to provide better
;;   or easier abtractions in assembly
;;
;; NOTE: This assumes FASM/Flat assembler x86_64, with format ELF64 Dynamic
;;   running on Linux
;; -------------------------------------------------------------------------
include 'linux.inc'         ; Macros and definitions for Linux syscalls, etc.

;; Make a string with length attached as <string>.len
macro make_string name, text& {
    name db text
    .len = $ - name
}

segment readable writeable
num_buf: times 24 db 0      ; Should be large enough for UINT64_MAX + sign
make_string newline, 0xA

segment executable
;; print_number: Print a number to STDOUT
;;   Input: RAX = number to print
print_number:
push rbx        ; Save clobbered registers
push rcx
push rdx
push rdi   
push r8

lea rdi, [num_buf]      ; RDI = &buffer
mov rbx, 10             ; Divisor

fill_number_buf_loop:
    xor rdx, rdx
    div rbx                 ; RAX:RDX / 10; RAX = quotient, RDX = remainder
    add dl, '0'             ; Convert int -> char
    mov [rdi], dl           ; Store next digit in buffer
    inc rdi                 ; Move to next digit spot in buffer
    test rax, rax           ; RAX > 0?
ja fill_number_buf_loop     ; Yes, keep going

;; Reverse buffer to print correctly
lea rax, [num_buf]      ; RAX = start of buffer
mov rbx, rdi            ; RBX = end of buffer + 1 from RDI
dec rbx                 ; End of buffer

mov r8, rbx             ; R8 = length of number buffer 
sub r8, rax             
inc r8                  ; +1 for 0-based indexing

swap_next_digit:
    mov cl, [rbx]           ; CL = last digit
    mov dl, [rax]           ; DL = first digit
    mov byte [rax], cl      ; Swap first and last digits
    mov byte [rbx], dl      
    inc rax                 ; 1st++
    dec rbx                 ; Last--

    cmp rax, rbx            ; 1st position > last position?
jbe swap_next_digit         ; No, keep swapping

;; Print number string
lea rbx, [num_buf]
write_buf rbx, r8

;; Restore clobbered registers
pop r8
pop rdi   
pop rdx
pop rcx
pop rbx        

ret     ; Return to caller

;; strncmp: Compare 2 strings with a max length
;; Inputs:
;;   RBX = str1
;;   RDX = str2
;;   RCX = count 
;; Output: RAX = 0 if not matching/false, 1 if matching/true
strncmp:
push rbx    ; Save clobbered registers
push rcx
push rdx
push r8
push r9
.cmp_loop:
    mov r8b, [rbx]
    cmp r8b, [rdx]  ; str1[i] == str2[i]?
    jne .no_match   ; No, leave
    inc rbx         ; str1++
    inc rdx         ; str2++
loop .cmp_loop

.match:
xor rax, rax
inc rax             ; 1 = true, match
jmp .end

.no_match:
xor rax, rax    ; 0 = false, no match

.end:
pop r9      ; Restore clobbered registers
pop r8
pop rdx     
pop rcx
pop rbx
ret

