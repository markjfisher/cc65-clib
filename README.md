# cc65-clib

BBC Micro cc65 clib in ROM. 

*** EXPERIMENTAL *** NOT TO BE USED IN PRODUCTION ***

This is only a test build but demonstrated moving some of the larger parts of 
the c-library into a sideways ROM

At present this is quite limited but does free up a lot of RAM space, there
is currently no mechanism for versioning or otherwise future-proofing the
ROM, it requires executables to use matching versions of the .lib file and 
.rom. It is intended that some form of vectoring/jump tables/live relocation
be used to allow programs built with and older clib to use a newer ROM

The ROM must be loaded in slot #1, there is so far no mechanism for 
discovering the presence and location of the ROM

