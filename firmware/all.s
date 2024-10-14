.section .text
.global _start

_start:
    # Load upper immediate
    lui x1, 0x1

    # Add immediate
    addi x2, x0, 10

    # Store word
    sw x2, 0(x1)

    # Load word
    lw x3, 0(x1)

    # Add
    add x4, x2, x3

    # Subtract
    sub x5, x4, x2

    # Shift left logical
    sll x6, x5, x2

    # Set less than
    slt x7, x6, x5

    # Set less than unsigned
    sltu x8, x7, x6

    # XOR
    xor x9, x8, x7

    # Shift right logical
    srl x10, x9, x8

    # Shift right arithmetic
    sra x11, x10, x9

    # OR
    or x12, x11, x10

    # AND
    and x13, x12, x11

    # Branch equal
    beq x13, x12, label_equal

    # Branch not equal
    bne x13, x11, label_not_equal

label_equal:
    # Jump and link
    jal x14, label_jump

label_not_equal:
    # Jump and link register
    jalr x15, 0(x14)

label_jump:
    # Branch less than
    blt x15, x14, label_less_than

    # Branch greater or equal
    bge x15, x14, label_greater_or_equal

label_less_than:
    # Branch less than unsigned
    bltu x15, x14, label_less_than_unsigned

    # Branch greater or equal unsigned
    bgeu x15, x14, label_greater_or_equal_unsigned

label_less_than_unsigned:
    # End of demo
    nop

label_greater_or_equal:
    # Immediate AND
    andi x16, x15, 0xF

label_greater_or_equal_unsigned:
    # Immediate OR
    ori x17, x16, 0xF

    # Immediate XOR
    xori x18, x17, 0xF

    # Immediate Shift Left Logical
    slli x19, x18, 1

    # Immediate Shift Right Logical
    srli x20, x19, 1

    # Immediate Shift Right Arithmetic
    srai x21, x20, 1

    # Fence instruction
    fence

    # Environment call
    ecall

    # Environment break
    ebreak

    # Unsigned Load Byte
    lbu x22, 0(x1)

    # Unsigned Load Halfword
    lhu x23, 0(x1)

    # Signed Load Byte
    lb x24, 0(x1)

    # Signed Load Halfword
    lh x25, 0(x1)

    # Store Byte
    sb x22, 1(x1)

    # Store Halfword
    sh x23, 2(x1)

    # Load Upper Immediate
    lui x26, 0xFFFFF

    # Add Upper Immediate to PC
    auipc x27, 0xFFFFF

    # Halt
    j halt
halt:
    j halt