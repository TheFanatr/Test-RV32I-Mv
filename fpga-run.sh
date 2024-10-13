./build_frimware.sh &
wait
# python3.13 talk.py -H localhost -p 8880 --retry-interval 5 --minor-pause 0.0 --major-pause 0.0 --write --check Write -f firmware/obj_dir/main.bin --start-address 0x00000000 --boot -o Progress &
python3.13 talk.py -H 10.0.0.105 -p 8880 --retry-interval 5 --minor-pause 0.0 --major-pause 0.01 --write --check On -f test.bin --start-address 0x00000000 --boot -o Fatal,Error,Status,Progress &
# python3.13 talk.py -H localhost -p 8880 --retry-interval 5 --minor-pause 0.0 --major-pause 0.0 --write --check On -f firmware/obj_dir/main.bin --start-address 0x00000000 --boot -o Fatal,Error,Status &
./run/obj_dir/Vrv32i
wait