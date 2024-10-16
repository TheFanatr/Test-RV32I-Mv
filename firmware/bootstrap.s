.section .entry, "ax"
.global _start
_start:
    addi sp, x0, 1024 
    j main
    ret
