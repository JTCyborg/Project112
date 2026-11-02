# Project112 — ATM Turbo 2+ video-mode demonstrator

Target: ATM Turbo 2+ v7.10 / UnrealSpeccy.

## Build

Run `build.bat` from the `112` directory. It assembles `src/main.asm` and creates:
- `project112.TRD`
- `list.txt` — SjASMPlus listing
- `map.txt` — symbol map

## Keyboard

Press Space to cycle through three ATM-native modes:
1. ATM 640x200 hardware multicolor.
2. ATM 320x200 EGA-style 16-color.
3. ATM 80x25 hardware text.

Sinclair 256x192 is temporarily excluded from the runtime cycle. Its D0=1 transition triggers the ATM RAM content permutation, so it needs a separate ROM-mediated transition/reload path.

## Startup and memory-swap handling

The TR-DOS BASIC loader is stored as `boot.b`. It does not change the video mode; it only loads `proj112.C` at address `$8000` and starts it. Video-mode initialization is owned by the program.

The three active ATM modes use values 2, 0 and 6; D0 remains zero while cycling, so the executable and its data remain in place.

## Memory layouts

- ATM 640x200: page 5 bitmap, page 1 attributes; even/odd columns use separate 8K halves.
- ATM EGA 320x200x16: four layers at $C000, $4000, $E000 and $6000.
- ATM 80x25: character codes in page 5, attributes in page 1.

## Validation status

Build and runtime validation must be performed with the current `build.bat` and UnrealSpeccy configured for ATM710, RAMSize=1024, AtmMemSwap=1, UsePalette=1 and ROMSET=ATM2. A successful log proves code execution; each renderer still requires visual verification.


## Current visual diagnosis (2026-11-02)

The latest repository screenshot `1.png` shows a colored mosaic rather than the expected character grid. The runtime log confirms that the drawing routine ran, but does not prove that the video controller fetched the CPU-mapped physical pages.

The 640x200 renderer's documented address arithmetic has been checked against the ATM2+ specification: page 5 bitmap, page 1 attributes, 40 bytes per scanline, and even/odd columns in the two 8K halves. Do not change this arithmetic or the glyph byte format until the physical page mapping and video fetch source have been verified.

The startup value is `#C2`, not `#82`. The two values differ in D6 (VE1); keep this consistent in the BASIC loader and runtime initialization.
