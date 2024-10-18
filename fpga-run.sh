./build_frimware.sh &
wait
python3.13 talk.py -H 10.0.0.105 -p 8880 --retry-interval 5 --minor-pause 0.01 --major-pause 0.05 --write --check Off -f firmware/obj_dir/main.bin --start-address 0x00000000 -o Fatal,Error,Status,Progress
wait