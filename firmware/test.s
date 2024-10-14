nop
add x1, x0, 5
add x2, x1, x1
add x3, x0, 15
# Store instructions
sb x2, 15(x3)
lb x4, 15(x3)