;;;
;;; FreeBSD x86_64 asm, used with nasm
;;; AOC 2021 Day3 part 2
;;;
%define NUM_BITS 12
;%define NUM_BITS 5

extern printf

global main

segment .text
main:
    cld                     ; String ops will increment RSI/RDI

    ;; OXYGEN ================================================
    lea rsi, [data]         ; Input data
    mov rbx, -1             ; Bit counter start value
    call get_next_bit_ones_and_zeros

    call set_oxygen_filter_value
    
    lea rsi, [data]
    call add_filtered_numbers

    cmp r9, 1               ; Only 1 number added? 
    je oxygen_done          ; Yes, got oxygen rating

    .filter_loop:
        lea rsi, [filtered_nums]  ; Will now continually filter oxygen numbers
        call get_next_bit_ones_and_zeros

        call set_oxygen_filter_value

        lea rsi, [filtered_nums]
        call add_filtered_numbers

        cmp r9, 1                ; Only 1 number added? 
    jne .filter_loop             ; No, keep filtering

    oxygen_done:
    ;; Get single number from array
    call get_num
    mov [oxygen_rating], bx  

    ;; CO2 =====================================================
    lea rsi, [data]         ; Input data
    mov rbx, -1             ; Bit counter start value
    call get_next_bit_ones_and_zeros

    call set_co2_filter_value
    
    lea rsi, [data]
    call add_filtered_numbers

    cmp r9, 1               ; Only 1 number added? 
    je co2_done             ; Yes, got co2 rating

    .filter_loop:
        lea rsi, [filtered_nums]     ; Will now continually filter co2 numbers
        call get_next_bit_ones_and_zeros

        call set_co2_filter_value
        
        lea rsi, [filtered_nums]
        call add_filtered_numbers

        cmp r9, 1               ; Only 1 number added? 
    jne .filter_loop            ; No, keep filtering

    co2_done:
    ;; Get single number from array
    call get_num
    mov [co2_rating], bx  

    ;; Multiply oxygen by co2 number
    xor rcx, rcx
    xor rdx, rdx
    mov cx, [oxygen_rating]
    mov dx, [co2_rating]  
    imul rcx, rdx  

    ;; Print (RCX) as int with C printf()
    ;;   Using SYSV amd64 ABI
    xor rax, rax            ; AL = # of vector arguments (0)
    lea rdi, [format_str]   ; 1st argument
    mov rsi, rcx            ; 2nd argument
    push rbx                ; 16byte align stack by pushing 8byte register before call
    call printf
    pop rbx                 ; 16byte align stack by popping 8byte register after call

    ret                     ; End program

;; END MAIN LOGIC ============================================

;; Subroutine to get number from data at rsi, put in bx
get_num:
    lea rsi, [filtered_nums]
    xor rbx, rbx            
    mov rcx, NUM_BITS
    .loop:
        xor ax, ax
        lodsb
        sub al, '0'         ; Convert char -> int
        shl ax, cl
        shr ax, 1
        or bx, ax
    loop .loop
    ret

;; Subroutine to count occurrences of 1s and 0s in a given bit column
;;   of data. Column to check is in RBX
get_next_bit_ones_and_zeros:
    inc rbx
    .loop:
        add rsi, rbx
        cmp byte [rsi], 0           ; EOF?
        je .done

        cmp byte [rsi], '1'
        je .one
        lea rdi, [zeros]
        jmp .next_bit

        .one:
        lea rdi, [ones]

        .next_bit:
        inc word [rdi]      ; Increase ones/zeros count
        sub rsi, rbx        ; Get start of number
        add rsi, NUM_BITS   ; Go to next number
    jmp .loop

    .done:
        ret

;; Subroutine to add filtered numbers to oxygen nums array
;;  RSI points to data to filter, 
;;  RBX holds bit of number to check
;;  R9 will hold number of valid, filtered data numbers
add_filtered_numbers:
    mov word [ones], 0      ; Clear ones/zeros arrays
    mov word [zeros], 0

    xor r9, r9              ; Count of filtered numbers
    xor rcx, rcx            ; Counter
    .loop:
        add rsi, rbx            ; Get current bit to check in number
        mov al, [rsi]
        sub rsi, rbx            ; RSI points to start of number
        cmp al, 0
        je .done

        cmp al, [filter_value]
        jne .next

        ;; Add to filtered numbers array
        lea rdi, [filtered_nums]
        imul r8, r9, NUM_BITS
        add rdi, r8             ; RDI points to number position in array
        mov cl, NUM_BITS 
        rep movsb               ; Copy number to oxygen nums position
        inc r9                  ; 1 more number added to filtered array
        jmp .loop

        .next:
        add rsi, NUM_BITS       ; Go to next number
    jmp .loop

    .done:
        ;; Set new array end point
        imul r8, r9, NUM_BITS
        lea rdi, [filtered_nums]
        add rdi, r8             ; Position after last number in array
        mov rcx, NUM_BITS
        xor rax, rax
        rep stosb               ; Fill 1 number of space with 0s for new "end" of array
        ret

;; Subroutine to set bit value to filter by ('0' or '1') for oxygen
set_oxygen_filter_value:
    mov ax, [ones]
    cmp ax, [zeros]
    jge .set_one            ; For oxygen, get filter_value bits number, or if equal set 1
    mov byte [filter_value], '0'
    jmp .done

    .set_one:
    mov byte [filter_value], '1'

    .done:
        ret

;; Subroutine to set bit value to filter by ('0' or '1') for co2
set_co2_filter_value:
    mov ax, [ones]
    cmp ax, [zeros]
    jl  .set_one            ; For co2, get lesser bits number, or if equal set 0
    mov byte [filter_value], '0'
    jmp .done

    .set_one:
    mov byte [filter_value], '1'

    .done:
        ret

segment .rodata
format_str: db "Oxygen * CO2: %d",10,0   

segment .data
ones: dw 0      
zeros: dw 0    
filter_value: db 0
oxygen_rating: dw 0
co2_rating: dw 0
filtered_nums: times 12000 db 0 

;%include "test_input.asm"
%include "input.asm"
