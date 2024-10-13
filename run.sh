./build_frimware.sh &
rm ./run/obj_dir/Vrv32i
cd run
verilator --relative-includes --cc --exe --build --timing --trace-fst --top-module rv32i -j 0 -Wno-lint -Wno-selrange -CFLAGS -fpermissive *.cpp ../rtl/*.sv ../rtl/*.v
cd ..
wait
rm run.fst
# python3.13 talk.py -H localhost -p 8880 --retry-interval 5 --minor-pause 0.0 --major-pause 0.0 --write --check Write -f firmware/obj_dir/main.bin --start-address 0x00000000 --boot -o Progress &
python3.13 talk.py -H localhost -p 8880 --retry-interval 5 --minor-pause 0.0 --major-pause 0.0 --write --check Off -f firmware/obj_dir/main.bin --start-address 0x00000000 --boot -o Fatal,Error,Status &
./run/obj_dir/Vrv32i
wait