#!/usr/bin/python

import subprocess

res = subprocess.check_output(['/usr/bin/yosys', '-p', 'read -sv rtl/*.sv; ls', '-Q', '-T'])
lines = str(res).split('modules:\\n')[1].split("$abstract\\\\")
lines = [l.strip().strip('"').strip("\\n") for l in lines[1:]]

mods = "["
for x in lines:
    try:
        print(subprocess.check_output(['/usr/bin/yosys', '-DTESTING'  ,'-p' , f"read -sv rtl/*.sv; prep -top {x}; write_json ./tmp/{x}.json"]))
        print(subprocess.check_output(['/usr/bin/netlistsvg', f'./tmp/{x}.json', '-o', f'./docs/{x}.svg']))
        pass
    except:
        pass
    mods += f'"{x}",'
mods.strip(',')
mods += "]"

datajs = f"function getModules() {{ return {mods};}}"
with open("./docs/data.js", "r+") as f:
    data = f.read()
    f.seek(0)
    f.write(datajs)
    f.truncate()