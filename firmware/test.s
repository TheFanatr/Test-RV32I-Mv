.section .text
.global _start

_start:
    nop
    # Setup preconditions
    # Using `lui` to load upper 20-bits and then adjusting lower 12-bits

    lui x7, 0x00001      # Load 1 into x7 (test register 7)
    lui x8, 0x00001      # Load 1 into x8 (test register 8)
    lui x9, 0x00000      # Load 0 into x9 (test register 9)
    lui x10, 0x00002     # Load 2 into x10 (test register 10)
    lui x11, 0x00002     # Load 2 into x11 (test register 11)
    lui x12, 0x00000     # Load 0 into x12 (test register 12)
    lui x13, 0x00001     # Load 1 into x13 (test register 13)
    lui x14, 0x00001     # Load 1 into x14 (test register 14)
    lui x15, 0x00002     # Load 2 into x15 (test register 15)
    lui x16, 0x00002     # Load 2 into x16 (test register 16)
    lui x17, 0x00001     # Load 1 into x17 (test register 17)
    lui x18, 0x00001     # Load 1 into x18 (test register 18)

    # Use x1 to check values
    # Use x6 as a dummy for branch instruction targets
    # Use `lui` for values, all values preconditions should match for successful jumps

    # beq - Branch if Equal
    beq x7, x8, label_beq
    j fail

label_beq:
    lui x1, 0x00001      # Mark pass

    # bne - Branch if Not Equal
    bne x9, x10, label_bne
    j fail

label_bne:
    lui x2, 0x00002      # Mark pass

    # blt - Branch if Less Than
    blt x11, x10, label_blt
    j fail

label_blt:
    lui x3, 0x00003      # Mark pass

    # bge - Branch if Greater or Equal
    bge x13, x12, label_bge
    j fail

label_bge:
    lui x4, 0x00004      # Mark pass

    # bltu - Branch if Less Than Unsigned
    bltu x14, x15, label_bltu
    j fail

label_bltu:
    lui x5, 0x00005      # Mark pass

    # bgeu - Branch if Greater or Equal Unsigned
    bgeu x16, x17, label_bgeu
    j fail

label_bgeu:
    lui x6, 0x00006      # Mark pass

    j end

fail:
    lui x19, 0xFFFFF      # Mark fail

end:
