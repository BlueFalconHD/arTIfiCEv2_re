# arTIfiCE v2 reverse engineering

This repository includes a working payload which you can write custom ASM into.
The TI-BASIC exploit (`GotoASM`) has been reverse engineered. See the technical write-up in [GotoAsm/explanation.md](GotoAsm/explanation.md).

## Building the exploit

1. To make an 8xp file, first assemble the exploit with a tool like `spasm-ng`:

  ```
  spasm -E exploit.asm exploit.bin
  ```

2. Then concatenate it with the GotoAsm prelude (see [explanation](GotoAsm/explanation.md)):

  ```
  cat prelude.bin exploit.bin > goToAsm.bin
  ```

3. Then use the python script to produce an 8xp file:

  ```
  python3 build8xp.py goToAsm.bin goToAsm.8xp
  ```

## Running the exploit
Upload the `goToAsm.8xp` file to your calculator using TI Connect CE, then run it from the `PRGM` menu.
