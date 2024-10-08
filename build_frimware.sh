mkdir -p tmp
riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -Os -Wall -Wextra -ffreestanding -nostdlib -fPIC -Wl,-Bstatic,-T./firmware/linker.ld,--no-warn-rwx -o ./tmp/main.o ./firmware/main.c
riscv64-linux-gnu-objcopy -O verilog ./tmp/main.o ./tmp/main.hex
riscv64-linux-gnu-objcopy -O binary ./tmp/main.o ./tmp/main.bin
