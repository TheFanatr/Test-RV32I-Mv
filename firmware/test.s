nop
add x2, x0, 2047
add x2, x2, x2 # 4094
add x2, x2, x2 # 8188
add x2, x2, x2 # 16376
add x2, x2, x2 # 32752
add x2, x2, x2 # 65504
add x2, x2, x2 # 131008
sw x2, 0(x0)
lw x4, 0(x0)
