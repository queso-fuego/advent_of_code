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

macro mac_syscall number*, arg1, arg2, arg3, arg4, arg5, arg6 {
    mov rax, number

    if ~ (arg1 eq )
        if arg1 eqtype [0]
            lea rdi, arg1
        else
            mov rdi, arg1
        end if
    end if

    if ~ (arg2 eq )
        if arg2 eqtype [0]
            lea rsi, arg2
        else
            mov rsi, arg2
        end if
    end if

    if ~ (arg3 eq )
        if arg3 eqtype [0]
            lea rdx, arg3
        else
            mov rdx, arg3
        end if
    end if

    if ~ (arg4 eq )
        if arg4 eqtype [0]
            lea r10, arg4
        else
            mov r10, arg4
        end if
    end if

    if ~ (arg5 eq )
        if arg5 eqtype [0]
            lea r8, arg5
        else
            mov r8, arg5
        end if
    end if

    if ~ (arg6 eq )
        if arg6 eqtype [0]
            lea r9, arg6
        else
            mov r9, arg6
        end if
    end if

    syscall
}

macro write_string string { mac_syscall SYS_WRITE, FD_STDOUT, [string], string#.len }

macro write_buf buf, len { mac_syscall SYS_WRITE, FD_STDOUT, [buf], len }

macro exit exit_code { mac_syscall SYS_EXIT, exit_code }

macro open file, flags { mac_syscall SYS_OPEN, file, flags, 0 }

macro close fd { mac_syscall SYS_CLOSE, fd }

macro read fd, buf, count { mac_syscall SYS_READ, fd, buf, count }

macro write fd, buf, count { mac_syscall SYS_WRITE, fd, buf, count }

macro lseek fd, offset, whence { mac_syscall SYS_LSEEK, fd, offset, whence }

macro mmap addr, length, prot, flags, fd, offset {
    mac_syscall SYS_MMAP, addr, length, prot, flags, fd, offset
}

macro munmap addr, length { mac_syscall SYS_MUNMAP, addr, length }

