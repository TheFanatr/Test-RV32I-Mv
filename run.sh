#!/bin/zsh
./build_frimware.sh &
rm ./run/obj_dir/Vrv32i
cd run
verilator --relative-includes --cc --exe --build --timing --trace-fst --top-module rv32i -j 0 -Wno-lint -Wno-selrange -CFLAGS -fpermissive *.cpp ../rtl/*.sv ../rtl/*.v
built=$?
cd ..
wait
if [ $built -eq 0 ]; then
    WANTED_STREAM_TEXT="Hello sailor.\nWhat's for breakfast?\n"
    python3.13 talk.py -H localhost -p 8880 --retry-interval 5 --minor-pause 0.0 --major-pause 0.0 --write --check Off -f firmware/obj_dir/main.bin --start-address 0x00000000 --boot --stream ${#WANTED_STREAM_TEXT} -o Fatal,Error,Status,Progress &
    ./run/obj_dir/Vrv32i
    wait
fi