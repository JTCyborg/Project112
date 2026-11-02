# Project112
ATM Turbo 2+ v7.10 video-mode demonstrator (migration in progress).

## UnrealSpeccy configuration

The repository unreal.ini is configured for ATM Turbo 2+ v7.10:
- HIMEM=ATM710
- RAMSize=1024
- Preset=ATM1_2_3.5MHz
- Border=small
- AtmMemSwap=0
- UsePalette=1
- ROMSET=ATM2

Restart UnrealSpeccy after changing the configuration. The selected ATM BIOS file must exist in the emulator directory (ATM2=bios_1_07_13.rom in this configuration).

## ATM Turbo 2+ video modes

The target hardware provides four principal display modes:
1. Sinclair 256x192
2. 640x200 hardware multicolor
3. 320x200 EGA, 16 colors
4. 80x25 hardware text

The mode register values in ATM system port #77 are 3, 2, 0 and 6 respectively. See 112/src/video_mode_control.asm.

**Migration status:** emulator configuration and ATM mode-code table are committed. The current main.asm and legacy mode_*.asm modules still contain Pentagon-specific memory mapping/renderers. Do not treat the program as a working ATM demo until the ATM memory mapping, pixel/attribute renderers, text-mode output, and safe mode-transition routine are completed. The exact remaining work is tracked in SCENARIO.md.

## Hardware references

- ATM Turbo 2+ technical description, PCB 7.00-7.10: https://zxpress.ru/ru/ezines/inferno/02/tehnicheskoe-opisanie-personalnogo-kompyutera-atm-turbo-2-struktura-pamyati-porty-vvoda-vyvoda
- Four ATM display modes and screen-memory organization: https://zxpress.ru/en/ezines/adventurer/01/detailed-overview-of-atm-turbo-2-video-modes-four-main-screens-with-different-resolutions-and
