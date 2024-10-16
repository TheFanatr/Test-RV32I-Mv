#!/bin/zsh
mkdir -p firmware/obj_dir
riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -Os -Wall -Wextra -ffreestanding -nostdlib -fPIC -Wl,-Bstatic,-T./firmware/linker.ld,--no-warn-rwx -o ./firmware/obj_dir/main.o ./firmware/main.c ./firmware/bootstrap.s 
riscv64-unknown-elf-objcopy -O verilog ./firmware/obj_dir/main.o ./firmware/obj_dir/main.hex
riscv64-unknown-elf-objcopy -O binary ./firmware/obj_dir/main.o ./firmware/obj_dir/main.bin

build_test() {
    riscv64-unknown-elf-as ./firmware/$1.s -march=rv32i -o ./firmware/obj_dir/$1.o -fPIC
    riscv64-unknown-elf-objcopy -O verilog ./firmware/obj_dir/$1.o ./firmware/obj_dir/$1.hex
    riscv64-unknown-elf-objcopy -O binary ./firmware/obj_dir/$1.o ./firmware/obj_dir/$1.bin
}

build_test all
build_test test
build_test branch
build_test bootstrap
