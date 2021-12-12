;;;
;;; FreeBSD x86_64 asm, used with nasm
;;; AOC 2021 Day11 part 2
;;;
%define LINE_END 10     ; Newline \n
%define FALSE 0
%define TRUE 1
%define LINE_LEN 10 

extern printf

global main

segment .text
main:
    cld                 ; String ops will increment RSI/RDI

    xor r8, r8          ; Current step

    new_step:
    xor r10, r10        ; Total number of flashes
    mov rsi, data  

    ;; Clear flashed array for next step
    mov rdi, flashed
    mov rcx, (LINE_LEN*LINE_LEN)+LINE_LEN
    mov al, FALSE
    rep stosb

    flash_loop:
        cmp rsi, EOF
        je .next_step

        cmp byte [rsi], LINE_END
        je .next_octopus

        mov rdi, rsi
        call check_flash

        .next_octopus:
        inc rsi
        jmp flash_loop

        .next_step:
        inc r8

        ;; Check if all octopi flashed this step
        cmp R10, LINE_LEN*LINE_LEN
        je done
    jmp new_step

    done:
        mov rcx, r8             ; First step where all octopi flashed

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

;; Subroutine for octopus flashes 
;; Looks like another BFS/DFS type of solution
;; Input:
;;   RDI = octopus (position in data)
;; Input/Output:
;;   R10 = number of flashes
check_flash:
    mov r11, rdi
    sub r11, data           ; Get offset into data
    mov r9, flashed
    add r9, r11             ; Go same offset into flashed array
    cmp byte [r9], TRUE     ; Already flashed this step?
    je .done                ; Yes, go on

    inc byte [rdi]
    cmp byte [rdi], '9'      
    jle .done               ; No flash, leave

    mov byte [rdi], '0'     ; Reset octopus energy level
    mov byte [r9], TRUE     ; Set flashed array position to true
    inc r10                 ; Increment flash count

    ;; Increment energy level of (up to) all 8 octopi surrounding this one
    ;; NW
    ;; Check if outside boundary
    cmp rdi, data               ; At start of input?
    je .N
    cmp byte [rdi-1], LINE_END  ; At start of line?
    je .N
    cmp rdi, data+LINE_LEN+1    ; On at least first line?
    jle .N
    push rdi
    sub rdi, LINE_LEN+2         ; Move 1 line up and 1 char left
    call check_flash
    pop rdi

    ;; N
    .N:
    ;; Check if outside boundary
    cmp rdi, data+LINE_LEN+1    ; On at least first line?
    jl .NE
    push rdi
    sub rdi, LINE_LEN+1         ; Move 1 line up
    call check_flash
    pop rdi

    ;; NE
    .NE:
    ;; Check if outside boundary
    cmp rdi, EOF-2              ; At end of input?
    je .W
    cmp byte [rdi+1], LINE_END  ; At end of line?
    je .W
    cmp rdi, data+LINE_LEN+1    ; On at least first line?
    jl .W
    push rdi
    sub rdi, LINE_LEN           ; Move 1 line up and 1 char right
    call check_flash
    pop rdi

    ;; W 
    .W:
    ;; Check if outside boundary
    cmp rdi, data           ; At start of input
    je .E
    cmp byte [rdi-1], LINE_END  ; At start of line?
    je .E
    push rdi
    dec rdi                 ; Move 1 char left
    call check_flash
    pop rdi

    ;; E 
    .E:
    ;; Check if outside boundary
    cmp rdi, EOF-2          ; At end of input?
    je .SW
    cmp byte [rdi+1], LINE_END  ; At end of line?
    je .SW
    push rdi
    inc rdi                 ; Move 1 char right
    call check_flash
    pop rdi

    ;; SW 
    .SW:
    ;; Check if outside boundary
    cmp rdi, EOF-(LINE_LEN+2)   ; On last line?
    jge .S
    cmp rdi, data               ; At start of input
    je .S
    cmp byte [rdi-1], LINE_END  ; At start of line?
    je .S
    push rdi
    add rdi, LINE_LEN           ; Move 1 line down and 1 char left
    call check_flash
    pop rdi

    ;; S 
    .S:
    ;; Check if outside boundary
    cmp rdi, EOF-(LINE_LEN+2)   ; On last line?
    jge .SE
    push rdi
    add rdi, LINE_LEN+1         ; Move 1 line down
    call check_flash
    pop rdi

    ;; SE
    .SE:
    ;; Check if outside boundary
    cmp rdi, EOF-(LINE_LEN+2)   ; On last line?
    jge .done
    cmp rdi, EOF-2              ; At end of input?
    je .done
    cmp byte [rdi+1], LINE_END  ; At end of line?
    je .done
    push rdi
    add rdi, LINE_LEN+2         ; Move 1 line down and 1 char right
    call check_flash
    pop rdi

    .done:
    ret

segment .data
flashed: times (LINE_LEN*LINE_LEN)+LINE_LEN db FALSE
x: db 0
y: db 0

%include "input.asm"
;%include "test_input.asm"

segment .rodata
format_str: db "%lld",10,0       
