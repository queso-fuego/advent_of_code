;;;
;;; FreeBSD x86_64 asm, used with nasm
;;; AOC 2021 Day9 part 2
;;;
%define LINE_END ' '
;%define LINE_LEN 10     ; Test input
%define LINE_LEN 100     ; Puzzle input
%define FALSE 0
%define TRUE 1

extern printf

global main

segment .text
main:
    cld                 ; String ops will increment RSI/RDI

    xor r8, r8          ; Sum of all risk levels of lowest points
    xor rax, rax        ; Temp

    lea rsi, [data]     
    next_char:
        lodsb   
        cmp rsi, EOF    ; At EOF?
        jae done
        cmp al, LINE_END
        je .end_of_line
        inc qword [x]       ; Next X position in line

        ;; Compare current X,Y number to its cardinal neighbors
        ;;   Up/Down/Left/Right:
        ;; Up
        .up:
        cmp qword [y], 0    ; On 1st line?
        je .down            ; Yes, can't compare above
        cmp al, byte [rsi-2-LINE_LEN]  ; Current char lower than 1 line up?
        jge next_char       ; No, skip this char

        ;; Down
        .down:
        cmp rsi, EOF-LINE_LEN   ; Next line past EOF?
        jae .left               ; Yes, skip checking down
        cmp al, byte [rsi+LINE_LEN]  ; Current char lower than 1 line down?
        jge next_char           ; No, skip this char

        ;; Left
        .left:
        cmp qword [x], 0    ; At start of line?
        je .right           ; Yes, can't compare left
        cmp al, byte [rsi-2]  ; Current char lower than its left?
        jge next_char       ; No, skip this char

        ;; Right
        .right:
        cmp qword [x], LINE_LEN-1   ; At end of line?
        je .found_basin             ; Yes, go on, can't compare right
        cmp al, byte [rsi]          ; Current char lower than its right?
        jge next_char               ; No, skip this char

        ;; Current X,Y number is lower than all its neighbors,
        ;;  set current basin to 1 for this point, then search
        ;;  each cardinal direction, if it is 1 greater and not 9
        ;;  add 1 for basin size, and start search from that point.
        ;; After searching all 4 points and adding 1 for each,
        ;;  then have found basin size.
        .found_basin:
        xor r8, r8      ; Reset current basin size
        mov rdi, rsi    ; Data pointer
        dec rdi         ; RSI is 1 past current point
        call search_basin

        ;; Check if basin size is larger than any of current 3 largest,
        ;;  if so, replace smallest with this one
        cmp r8, [basin_sizes]
        jle next_char
        mov [basin_sizes], r8

        ;; Sort basin sizes, so that the smallest is always first
        mov rax, [basin_sizes]
        cmp rax, [basin_sizes+8]
        jle .check_2
        ;; Swap basin sizes 1 & 2
        mov rbx, [basin_sizes+8]
        mov [basin_sizes+8], rax
        mov [basin_sizes], rbx

        .check_2:
        mov rax, [basin_sizes+8]
        cmp rax, [basin_sizes+16]
        jle next_char
        ;; Swap basin sizes 2 & 3
        mov rbx, [basin_sizes+16]
        mov [basin_sizes+16], rax
        mov [basin_sizes+8], rbx

        jmp next_char

        .end_of_line:
        mov qword [x], -1   ; Set X,Y values for next line
        inc qword [y]
    jmp next_char

    done:
        ;; Answer is product of 3 largest basin sizes
        mov r8, [basin_sizes]
        imul r8, qword [basin_sizes+8]
        imul r8, qword [basin_sizes+16]

        mov rcx, r8

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

;; Search current neighbors from given point to fill out basin
;;   and add to basin's size. Recursive implementation.
;; I think this is technically a BFS or DFS algorithm
;; Input: 
;;   RDI points to current point to search from
;;   R8 = basin size = 0
;; Output:
;;   R8 = basin size
search_basin:
    cmp byte [rdi], '9' ; Stop when hit 9
    je .done

    mov r10, rdi
    sub r10, data       ; Get offset into data
    lea r9, [seen]
    add r9, r10         ; Use same offset into seen array
    cmp byte [r9], TRUE
    je .done            ; Already been here, go on
    inc r8              ; Current point not 9, increment basin size
    mov byte [r9], TRUE ; Set this point as seen

    ;; Search up
    ;; Check if on first line before calling
    cmp rdi, data+LINE_LEN+1    ; Is RDI on first line?
    jl .down                    ; Yes, skip
    push rdi
    sub rdi, LINE_LEN+1         ; RDI points to char 1 line up
    call search_basin
    pop rdi

    ;; Search down
    .down:
    ;; Check if on last line before calling
    cmp rdi, EOF-(LINE_LEN+1)   ; Next line past EOF?
    jge .left               ; Yes, skip
    push rdi
    add rdi, LINE_LEN+1     ; RDI points to char 1 line down
    call search_basin
    pop rdi

    ;; Search left
    .left:
    ;; Check if on first char before calling
    cmp rdi, data       ; At start of input?
    je .right           ; Yes, skip
    cmp byte [rdi-1], LINE_END  ; At start of line?
    je .right           ; Yes, skip
    push rdi
    dec rdi             ; RDI points to char at left
    call search_basin
    pop rdi

    ;; Search right
    .right:
    ;; Check if on last char before calling
    cmp rdi, EOF-2              ; At end of input?
    je .done                    ; Yes, skip
    cmp byte [rdi+1], LINE_END  ; At end of line?
    je .done                    ; Yes, skip
    push rdi
    inc rdi
    call search_basin
    pop rdi

    .done:
        ret

segment .data
x: dq -1
y: dq 0
basin_sizes: times 3 dq 0   ; 3 largest basin sizes
seen: times (LINE_LEN*LINE_LEN)+LINE_LEN db FALSE

segment .rodata
format_str: db "%lld",10,0       

%include "input.asm"
;%include "test_input.asm"
