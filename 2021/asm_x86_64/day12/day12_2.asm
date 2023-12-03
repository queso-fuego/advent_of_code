;;;
;;; FreeBSD x86_64 asm, used with nasm
;;; AOC 2021 Day12 part 2
;;;
%define LINE_END 10     ; Newline \n
%define FALSE 0
%define TRUE 1
%DEFINE MAX_NODES 25

extern printf

global main

segment .text
main:
    cld             ; String ops will increment RSI/RDI

    mov rsi, data 
    input_loop:
        cmp rsi, EOF
        jge start_dfs

        ;; Clear left and right nodes
        xor rcx, rcx
        xor rax, rax
        mov rdi, left_node
        mov cl, 12
        rep stosb                       ; Left/right nodes are contiguous

        ;; Get left node
        mov rdi, left_node
        .left_loop:
            cmp byte [rsi], '-' 
            je .right
            movsb
        jmp .left_loop

        ;; Get right node
        .right:
        lodsb
        mov rdi, right_node
        .right_loop:
            cmp byte [rsi], LINE_END
            je .after
            movsb
        jmp .right_loop

        .after:
        ;; graph[left_index][right_index] = true;
        mov rdi, left_node
        call get_node_index
        mov [left_index], rax

        mov rdi, right_node
        call get_node_index
        mov [right_index], rax

        imul rbx, [left_index], MAX_NODES   ; Get row offset of [row][col]
        add rbx, [right_index]              ; Add col offset to get [row][col]
        mov byte [graph+rbx], TRUE          ; graph[row][col] = true;

        ;; graph[right_index][left_index] = true;
        imul rbx, [right_index], MAX_NODES  ; Get row offset of [row][col]
        add rbx, [left_index]               ; Add col offset to get [row][col]
        mov byte [graph+rbx], TRUE          ; graph[row][col] = true;

        lodsb
    jmp input_loop

    ;; After getting all nodes in graph and arrays, traverse through graph
    start_dfs:
        mov rdi, left_node          ; Set "start" node
        mov rsi, start_node
        mov cl, 6
        rep movsb

        mov rsi, end_node
        mov cl, 6
        rep movsb

        mov rdi, left_node
        call get_node_index
        mov [left_index], rax

        mov rdi, right_node
        call get_node_index
        mov [right_index], rax

        ;; Set start node as visited first
        mov rbx, [left_index]
        mov byte [visited+rbx], TRUE    ; visited[start] = true;

        ;; DFS for "start" to "end" graph nodes, no small caves
        ;;   visited twice (yet)
        mov rax, [left_index]
        mov rbx, [right_index]
        mov r9, FALSE
        call dfs            

        mov rcx, [count]            ; # of total paths

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

;; Subroutine: DFS the graph
;; Input:
;;   RAX = starting node index ("start" node)
;;   RBX = ending node index ("end" node)
;;   R9 = boolean flag for visited small cave 2x y/n
dfs:
    cmp rax, rbx        ; Reached end from start?
    jne .loop
    inc qword [count]   ; # of paths += 1
    jmp .done           ; Return

    .loop:
    xor rcx, rcx                ; i = 0
    .for_loop:
        imul r8, rax, MAX_NODES ; Row offset for graph[a][i]
        add r8, rcx             ; Add col offset for graph[a][i]
        cmp byte [graph+r8], FALSE
        je .next                ; graph[a][i] == 0/false

        ;; Check if big/small cave
        imul rdx, rcx, 6
        lea r10, [nodes+rdx]    ; nodes[index]

        xor rdx, rdx            ; Init to 0/False
        cmp byte [r10], 'A'     ; Is first char uppercase?
        jl .after               ; Nope
        cmp byte [r10], 'Z'
        jg .after               ; Nope x2
        inc rdx                 ; Yes, it's a big cave

        .after:
        cmp rdx, TRUE            ; is_big_cave?
        jne .small_cave          ; No, it's a small cave

        .nested_dfs:
            push rax
            push rcx
            push r9
            mov rax, rcx        ; new starting index = i
            call dfs            ; ending index is the same
            pop r9
            pop rcx
            pop rax

            mov byte [visited+rcx], FALSE   ; visited[i] = false;
            jmp .next

        .small_cave:
            cmp byte [visited+rcx], TRUE    ; visited[i] == true?
            je .visited

            mov byte [visited+rcx], TRUE    ; visited[i] = true;

            ;; Nested dfs
            push rax
            push rcx
            push r9
            mov rax, rcx        ; new starting index = i
            call dfs            ; ending index is the same
            pop r9
            pop rcx
            pop rax

            mov byte [visited+rcx], FALSE   ; visited[i] = false;
            jmp .next

            .visited:
            cmp r9, TRUE            ; Visited this small cave twice?
            je .next
            cmp rcx, [left_index]   ; i == start node?
            je .next

            ;; Nested dfs
            push rax
            push rcx
            push r9
            mov r9, TRUE        ; Visited twice now
            mov rax, rcx        ; new starting index = i
            call dfs            ; ending index is the same
            pop r9
            pop rcx
            pop rax

        .next:
        inc rcx                 ; i++
        cmp rcx, [num_nodes]   ; i < num_nodes
    jl .for_loop

    .done:
    ret

;; Subroutine: Compare 2 NULL terminated strings, similar to C strcmp()
;; Input:
;;   RSI = string A
;;   RDI = string B
;; Output:
;;   RAX is positive for string A > B, 0 for A = B, negative for A < B
strcmp:
    .loop:
        cmpsb       ; [rsi] == [rdi]? and Inc RSI & RDI by 1
        jne .done
        cmp byte [rsi], 0
        je .done
        cmp byte [rdi], 0
        je .done
    jmp .loop

    .done:
        movsx rax, byte [rsi-1]
        sub al, byte [rdi-1]
        ret

;; Subroutine: Get a graph index given the name of a graph node
;; Input:
;;   RDI = node name
;; Output:
;;   RAX = index
get_node_index:
    xor rcx, rcx
    .for_loop:
        push rdi
        push rsi
        push rcx

        mov rsi, rdi                ; Node name
        imul rcx, rcx, 6
        lea rdi, [nodes+rcx]                ; Offset into nodes array
        call strcmp                 ; strcmp(node_name, nodes[i]);

        pop rcx
        pop rsi
        pop rdi

        cmp al, 0                   ; strcmp == true? Found node?
        jne .next

        ;; strcmp is true, return index of node
        mov rax, rcx
        jmp .done

        .next:
        inc rcx
        cmp rcx, [num_nodes]
    jl .for_loop

    ;; Else add to nodes:
    ;; nodes[num_nodes] = node_name
    push rdi
    push rsi

    mov rsi, rdi            ; RSI = Node name
    imul rax, [num_nodes], 6
    lea rdi, [nodes+rax]  ; RDI = nodes[num_nodes]
    mov rcx, 6
    rep movsb               ; nodes[num_nodes] = node name

    pop rsi
    pop rdi

    mov rax, [num_nodes]   ; return current size with new node
    inc qword [num_nodes]  ; num_nodes++

    .done:
    ret

segment .data
graph:   times MAX_NODES*MAX_NODES db FALSE   ; Graph of nodes
visited: times MAX_NODES db FALSE   ; Visited node y/n

;; String names for each graph node/node, longest name is "start",
;;   which is 5 chars, using 6 to guarantee an ending 0/NULL 
nodes: times MAX_NODES*6 db 0 
num_nodes: dq 0                 ; Total # of graph nodes/nodes

left_node:  times 6 db 0
right_node: times 6 db 0
left_index:  dq 0               ; Index of left node in nodes array
right_index: dq 0               ; Index of right node in nodes array

count: dq 0                     ; Total # of distinct paths, final answer

segment .rodata
format_str: db "%lld",10,0       

start_node: db "start",0    ; 6 length
end_node: db "end",0,0,0    ; 6 length

%include "input.asm"
;%include "test_input.asm"
