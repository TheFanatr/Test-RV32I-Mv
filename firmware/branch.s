.section .text
.global _start

_start:
    nop
    # Setup preconditions
    # Using `lui` to load upper 20-bits and then adjusting lower 12-bits

    # BEQ
    lui  x7, 0x00001     # Load 1 into x7 (test register 1-A)
    lui  x8, 0x00001     # Load 1 into x8 (test register 1-Z)

    # BNE
    lui  x9, 0xFFFFD     # Load 20-bit -3 into x9 (test register 2-A)
    srai x9, x9, 12      # arithmentic right shift x9 12 bits to make the register hold 32-bit -3
    
    lui x10, 0x00003     # Load 3 into x10 (test register 2-Z)

    # BLT
    lui x11, 0xFFFFB     # Load 20-bit -5 into x11 (test register 3-A)
    srai x11, x11, 12    # arithmentic right shift x11 12 bits to make the register hold 32-bit -5

    lui x12, 0x00005     # Load 5 into x12 (test register 3-Z)

    # BGE
    lui x13, 0x00005     # Load 5 into x13 (test register 4-A)

    lui x14, 0xFFFFB     # Load 20-bit -5 into x14 (test register 4-Z)
    srai x14, x14, 12    # arithmentic right shift x14 12 bits to make the register hold 32-bit -5

    # BLTU
    lui x15, 0x00007     # Load 7 into x15 (test register 5-A)
    lui x16, 0x00009     # Load 9 into x16 (test register 5-Z)

    # BGEU
    lui x17, 0x00009     # Load 9 into x17 (test register 6-A)
    lui x18, 0x00007     # Load 7 into x18 (test register 6-Z)

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
    blt x11, x12, label_blt
    j fail

label_blt:
    lui x3, 0x00003      # Mark pass

    # bge - Branch if Greater or Equal
    bge x13, x14, label_bge
    j fail

label_bge:
    lui x4, 0x00004      # Mark pass

    # bltu - Branch if Less Than Unsigned
    bltu x15, x16, label_bltu
    j fail

label_bltu:
    lui x5, 0x00005      # Mark pass

    # bgeu - Branch if Greater or Equal Unsigned
    bgeu x17, x18, label_bgeu
    j fail

label_bgeu:
    lui x6, 0x00006      # Mark pass

    j end

fail:
    lui x19, 0xFFFFF      # Mark fail

end: