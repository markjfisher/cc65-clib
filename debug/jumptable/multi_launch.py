import time, sys
sys.path.insert(0, "/home/markf/dev/bbc/beebium/clients/beebium-python-client/src")
from beebium.client import Beebium
from beebium.client.screen import screen_contains
ROM="/home/markf/dev/bbc/beebium/roms"; SERVER="/home/markf/dev/bbc/beebium/build-release/src/server/beebium-model-b"
CLIB="/home/markf/dev/bbc/cc65-clib/roms/clib.rom"
def once(i):
    ex=["--sideways","12:rom:"+ROM+"/acorn-dfs_2_26.rom","--fdc","acorn-1770","--floppy","0:VECFAIL.ssd","--sideways","13:rom:"+CLIB]
    with Beebium.launch(server_filepath=SERVER, mos_filepath=ROM+"/acorn-mos_1_20.rom", basic_filepath=ROM+"/bbc-basic_2.rom", extra_args=ex) as bbc:
        bbc.debugger.reset(); bbc.debugger.run(); time.sleep(1.5)
        # is the CLIB ROM actually loaded in slot 13 this launch?
        try: rom_ok = bbc.sideways.read_slot_data(13,9,9)==b'cc65 CLIB'
        except Exception as e: rom_ok=("ERR:%s"%e)
        bbc.system.set_speed_multiplier(0.0)
        bbc.keyboard.type("*RUN VECFAIL\r"); time.sleep(2.5); bbc.debugger.stop()
        done = screen_contains(bbc,"DONE")
        print("launch %d: clib_rom_in_slot13=%s  program_DONE=%s" % (i, rom_ok, done))
for i in range(6): once(i)
