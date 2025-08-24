# cc65-clib

BBC Micro cc65 clib in ROM.

Forked from https://github.com/dominicbeesley/cc65-clib
added rom-detection, and changes to move more functions into ROM (e.g. osfile_*)

*** EXPERIMENTAL *** NOT TO BE USED IN PRODUCTION ***

At present this is quite limited but does free up a lot of RAM space, there
is currently no mechanism for versioning or otherwise future-proofing the
ROM, it requires executables to use matching versions of the .lib file and 
.rom. It is intended that some form of vectoring/jump tables/live relocation
be used to allow programs built with and older clib to use a newer ROM

## Build System

The build process uses scripts to analyze object file dependencies and generate
ROM/stub interfaces.

- **Python scripts (default)**: `clib_imports.py`, `clib_stubs.py`
- **Perl scripts**: DEPRECATED: `clib_imports.pl`, `clib_stubs.pl`

The perl scripts no longer maintain functional parity with python, missing some of the copying
steps. TODO: restore parity or ditch perl.

```bash
cd src && make
```

See `PYTHON_SCRIPTS.md` for detailed documentation.

### Integration with cc65 Project

The build system automatically copies generated manifest files to the cc65 project
to ensure proper ROM/local function splitting. This uses loose coupling via the
`CC65_SRC` environment variable:

- **Default location**: `../../cc65` (sibling directory)
- **Custom location**: Set `CC65_SRC` environment variable

```bash
# Use default cc65 location
cd src && make

# Use custom cc65 src location  
CC65_SRC=/path/to/your/cc65 make
```

The build will report if the cc65 directory is not found but will not fail,
allowing the cc65-clib project to be built independently, however it will not be able
to copy artifacts from its build needed for cc65 to build bbc-clib target.

