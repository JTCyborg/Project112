# Project112 — ATM Turbo 2+ v7.10 video-mode demonstrator

Target: ATM Turbo 2+ v7.10 / UnrealSpeccy.

## Build

Run `build.bat` from the `112` directory. It assembles `src/main.asm` and creates `project112.TRD`, `list.txt` and `map.txt`.

## Keyboard

Space cycles through three ATM-native modes:
1. ATM 640x200 hardware multicolor.
2. ATM 320x200 EGA-style 16-color.
3. ATM 80x25 hardware text.

Sinclair 256x192 remains outside this cycle until a safe ROM-mediated transition is implemented.

## System port and memory mapping

The system mode port is accessed at **#FC77**, not #FD77. A8=0 disables the ATM page manager (PEN); A9=0 keeps DOSEN active. This is required for the conventional 7FFD page mapping used by the renderers. BASIC selects ATM 640x200 (value #82) before loading the machine code. The three active modes use values 2, 0 and 6; D0 stays zero while cycling.

The initial 7FFD value #11 selects RAM page 1 in the C000 window while page 5 remains at 4000. The screen renderer accesses page 5 at $4000/$6000 and page 1 at $C000/$E000.

## Video memory layouts

- **640x200:** page 5 contains bitmap bytes; page 1 contains matching attributes. Each scanline is 40 bytes per 8K half. Even and odd character columns use separate halves. Attribute format follows ATM: INK bits 0,1,2,6; PAPER bits 3,4,5,7.
- **320x200 EGA:** every 8-pixel character cell produces four two-pixel bytes. Their locations, in left-to-right order, are page 1 first half ($C000), page 5 first half ($4000), page 1 second half ($E000), page 5 second half ($6000). The left pixel uses bits 0,1,2,6; the right pixel uses bits 3,4,5,7.
- **80x25 text:** character codes use page 5 offset $01C0 + row*64 + column/2. Even/odd character columns are split across the two halves. Attribute halves are crossed: even attributes in page 1 second half, odd attributes in page 1 first half. Glyphs come from the ATM character ROM, not the software font.

## Validation

The source still requires an actual SjASMPlus build and UnrealSpeccy visual test. Verify all three modes, text character ROM mapping, palette and screen geometry. Do not mark a mode accepted until its screen is visually correct.
