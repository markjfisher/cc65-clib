import time, sys
sys.path.insert(0, "/home/markf/dev/bbc/beebium/clients/beebium-python-client/src")
from beebium.client import Beebium
from beebium.client.screen import dump_screen
ROM="/home/markf/dev/bbc/beebium/roms"; SERVER="/home/markf/dev/bbc/beebium/build-release/src/server/beebium-model-b"
CLIB="/home/markf/dev/bbc/cc65-clib/roms/clib.rom"
name=sys.argv[1]; ssd=name+".ssd"
ex=["--sideways","12:rom:"+ROM+"/acorn-dfs_2_26.rom","--fdc","acorn-1770","--floppy","0:"+ssd,"--sideways","13:rom:"+CLIB]
with Beebium.launch(server_filepath=SERVER, mos_filepath=ROM+"/acorn-mos_1_20.rom", basic_filepath=ROM+"/bbc-basic_2.rom", extra_args=ex) as bbc:
    bbc.debugger.reset(); bbc.debugger.run(); time.sleep(1.5); bbc.system.set_speed_multiplier(0.0)
    bbc.keyboard.type("*RUN "+name+"\r"); time.sleep(2.0)
    samples=[]
    for _ in range(3):
        bbc.debugger.stop(); samples.append((bbc.cpu.registers.pc, bbc.memory.address.peek[0xF4])); bbc.debugger.run(); time.sleep(0.1)
    bbc.debugger.stop()
    print("=== %s ===" % name)
    for pc,f4 in samples: print("  PC=%04X ROMSEL($F4)=%02X" % (pc,f4))
    print(dump_screen(bbc))
