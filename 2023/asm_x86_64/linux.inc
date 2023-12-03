NULL = 0

FD_STDIN  = 0
FD_STDOUT = 1
FD_STDERR = 2

SYS_READ   = 0
SYS_WRITE  = 1
SYS_OPEN   = 2
SYS_CLOSE  = 3
SYS_LSEEK  = 8
SYS_MMAP   = 9
SYS_MUNMAP = 11
SYS_EXIT   = 60

O_RDONLY = 00
O_WRONLY = 01
O_RDWR   = 02

SEEK_SET = 0
SEEK_CUR = 1
SEEK_END = 2

PROT_NONE  = 0
PROT_READ  = 1
PROT_WRITE = 2
PROT_EXEC  = 4

MAP_SHARED = 0x01

macro write_string string {
    mov rax, SYS_WRITE
    mov rdi, FD_STDOUT
    lea rsi, [string]
    mov rdx, string#.len
    syscall
}

macro write_strings [string] {
    mov rax, SYS_WRITE
    mov rdi, FD_STDOUT
    lea rsi, [string]
    mov rdx, string#.len
    syscall
}

macro write_buf buf, len {
    mov rax, SYS_WRITE
    mov rdi, FD_STDOUT
    mov rsi, buf
    mov rdx, len
    syscall
}

macro exit exit_code {
    mov rax, SYS_EXIT
    mov rdi, exit_code
    syscall
}

macro open file, flags {
    mov rax, SYS_OPEN
    lea rdi, [file]
    mov rsi, flags
    xor rdx, rdx
    syscall
}

macro close fd {
    mov rax, SYS_CLOSE
    mov edi, fd
    syscall
}

macro read fd, buf, count {
    mov rax, SYS_READ
    mov edi, fd
    lea rsi, [buf]
    mov rdx, count
    syscall
}

macro write fd, buf, count {
    mov rax, SYS_WRITE
    mov edi, fd
    lea rsi, [buf]
    mov rdx, count
    syscall
}

macro lseek fd, offset, whence {
    mov rax, SYS_LSEEK
    mov edi, fd
    mov rsi, offset
    mov rdx, whence
    syscall
}

macro mmap addr, length, prot, flags, fd, offset {
    mov rax, SYS_MMAP
    mov rdi, addr
    mov rsi, length
    mov rdx, prot
    mov r10, flags
    mov r8d, fd
    mov r9, offset
    syscall
}

macro munmap addr, length {
    mov rax, SYS_MUNMAP
    mov rdi, addr
    mov rsi, length
    syscall
}

