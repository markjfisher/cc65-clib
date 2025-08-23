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

## Build System

The build process uses scripts to analyze object file dependencies and generate
ROM/stub interfaces. Both Perl and Python versions are available:

- **Python scripts (default)**: `clib_imports.py`, `clib_stubs.py` 
- **Perl scripts**: `clib_imports.pl`, `clib_stubs.pl`

To build with Python scripts:
```bash
cd src && make
```

To build with Perl scripts:
```bash  
cd src && make SCRIPT_LANG=perl
```

See `PYTHON_SCRIPTS.md` for detailed documentation of the Python equivalents.

