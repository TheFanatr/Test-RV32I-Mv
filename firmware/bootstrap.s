.section .entry, "ax"
.global _start
_start:
    addi sp, x0, 1024
    call main
    j _exit

.section .exit, "ax"
_exit: