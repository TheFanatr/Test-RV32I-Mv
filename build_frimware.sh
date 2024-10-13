mkdir -p firmware/obj_dir
riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -Os -Wall -Wextra -ffreestanding -nostdlib -fPIC -Wl,-Bstatic,-T./firmware/linker.ld,--no-warn-rwx -o ./firmware/obj_dir/main.o ./firmware/main.c
riscv64-unknown-elf-objcopy -O verilog ./firmware/obj_dir/main.o ./firmware/obj_dir/main.hex
riscv64-unknown-elf-objcopy -O binary ./firmware/obj_dir/main.o ./firmware/obj_dir/main.bin

riscv64-unknown-elf-as ./firmware/test.s -march=rv32i -o ./firmware/obj_dir/test.o -fPIC
riscv64-unknown-elf-objcopy -O verilog ./firmware/obj_dir/test.o ./firmware/obj_dir/test.hex
riscv64-unknown-elf-objcopy -O binary ./firmware/obj_dir/test.o ./firmware/obj_dir/test.bin