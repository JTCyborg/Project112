; =========================================================================
; PROJECT112 — ZX SPECTRUM / ATM TURBO 2+ v7.10 VIDEO MODE TEST
; Target: ATM710 / UnrealSpeccy
; Fixed via Stack Trampoline in CPU Window 3.
; =========================================================================

        DEVICE ZXSPECTRUM128
        EMPTYTRD "project112.TRD"

        ORG     $8000

Project112Entry:
        LD      A,'Z'
        OUT     (#EF),A
        JP      Init_Z80_System112

; -------------------------------------------------------------------------
; Initial setup: native Sinclair 128K layout at start.
; -------------------------------------------------------------------------
Init_Z80_System112:
        DI
        LD      (Saved_SP_112),SP
        LD      SP,$BFFF

        LD      HL,Debug_BuildVersion112
        CALL    DebugPrintString112
        LD      HL,Debug_RuntimeStart112
        CALL    DebugPrintString112

        ; Сначала открываем теневые порты ATM через TR-DOS ROM.
        ; Важно: до этого места не переключать ROM через #7FFD и не
        ; обращаться напрямую к теневому системному порту #FF77.
        CALL    OpenATMShadowPorts112

        ; После активации DOSEN можно выбрать стандартную страницу ZX-128.
        ; A9=0 в системном порту сохраняет доступ к теневым портам.
        XOR     A
        LD      BC,$7FFD
        OUT     (C),A

        XOR     A
        LD      (Current_Mode_Index),A
        CALL    DrawDemoScreen
        LD      HL,Debug_Ready112
        CALL    DebugPrintString112
        JP      MainLoop112

; -------------------------------------------------------------------------
; ATM shadow-port unlock trampoline.
; Requires TR-DOS ROM mapped at #3D2F and its OUT (C),A entry at #2A53.
; The pushed return chain is: #3D2F -> #2A53 -> ShadowPortsOpened -> caller.
; -------------------------------------------------------------------------
OpenATMShadowPorts112:
        LD      BC,OpenATMShadowPortsDone112
        PUSH    BC
        LD      BC,#2A53
        PUSH    BC
        LD      BC,#0177               ; A9=0 (CPM), A14=0 (PEN2)
        LD      A,$C3                  ; RG=3, VE1=1, VE0=1
        JP      #3D2F
OpenATMShadowPortsDone112:
        RET

; -------------------------------------------------------------------------
; Main Loop & Debug Output
; -------------------------------------------------------------------------
MainLoop112:
        INCLUDE "src/keyboard.asm"

DebugPrintString112:
        PUSH    AF
        PUSH    HL
DebugPrintLoop112:
        LD      A,(HL)
        OR      A
        JR      Z,DebugPrintDone112
        OUT     (#EF),A
        INC     HL
        JR      DebugPrintLoop112
DebugPrintDone112:
        POP     HL
        POP     AF
        RET

; -------------------------------------------------------------------------
; Video Drivers & Modules (Includes)
; -------------------------------------------------------------------------
        INCLUDE "src/video_mode_control.asm"
        INCLUDE "src/mode_standard.asm"
        INCLUDE "src/mode_atm.asm"

; -------------------------------------------------------------------------
; Runtime Data & Constants
; -------------------------------------------------------------------------
Saved_SP_112:          DW 0
Current_Mode_Index:    DB 0
Temp_Character112:     DB 0
Temp_X112:             DB 0
Temp_Y112:             DB 0
GlyphLine112:          DB 0
FontPointer112:        DW 0
Temp_FontByte112:      DB 0
Demo_Character112:     DB 32
Demo_Row112:           DB 0
Demo_Column112:        DB 0
Grid_Width112:         DB 32
Grid_Height112:        DB 24
ATM_Offset112:         DW 0
ATM_Parity112:         DB 0
ColorShiftByte112:     DB 0
ColorPlaneIndex112:    DB 0
ColorByte112:          DB 0

Debug_BuildVersion112: DEFM "P112 BUILD ATM710-STACK-20261103.04",13,10,0
Debug_RuntimeStart112: DEFM "PROJECT112 ATM710 START",13,10,0
Debug_ScreenDrawn112:  DEFM "ATM SCREEN DRAWN",13,10,0
Debug_Ready112:        DEFM "VIDEO MODE TEST READY",13,10,0
Debug_RawPattern112:   DEFM "ATM640 RAW MEMORY PATTERN",13,10,0
Debug_SpacePressed112: DEFM "SPACE: NEXT ATM MODE",13,10,0
Debug_ModeApplied112:  DEFM "VIDEO MODE APPLIED",13,10,0

Text_ModePrefix112:    DEFM "MODE: ",0

Mode_Name_Pointers:
        DW ModeName_Sinclair112
        DW ModeName_ATM640112
        DW ModeName_ATMEGA112
        DW ModeName_ATMText112

ModeName_Sinclair112:  DEFM "SINCLAIR 256x192",0
ModeName_ATM640112:   DEFM "ATM 640x200 MULTICOLOR",0
ModeName_ATMEGA112:   DEFM "ATM EGA 320x200x16",0
ModeName_ATMText112:  DEFM "ATM TEXT 80x25",0

ATM_ColorPairValues112:
        DB      $00,$B8,$47,$FF

ATM_EGA_PlaneBases112:
        DW      $C000,$4000,$E000,$6000

        ALIGN   256
Font88_112:
        INCBIN  "src/font88.bin"

ProgramEnd112:

; =========================================================================
; TR-DOS BASIC loader ( sjasmplus fixed )
; =========================================================================
        ORG     $B000
CLEAR       EQU $FD
LOAD        EQU $EF
CODE        EQU $AF
REM         EQU $EA
RANDOMIZE   EQU $F9
USR         EQU $C0
OUT_CMD     EQU $DF
VAL         EQU $B0

basic_loader:
        DB      0,10
        DW      l10_len
l10:    DB      OUT_CMD, "239", $0E, $00, $00, $EF, $00, $00, ",", "1", $0E, $00, $00, $01, $00, $00, ":", CLEAR, "32767", $0E, $00, $00, $7F, $FF, $00, $0D
l10_len EQU     $-l10

        DB      0,11
        DW l11_len
l11:    DB      OUT_CMD, VAL, 34, "239", 34, ",", VAL, 34, "80", 34, ":"
        DB      OUT_CMD, VAL, 34, "239", 34, ",", VAL, 34, "49", 34, ":"
        DB      OUT_CMD, VAL, 34, "239", 34, ",", VAL, 34, "49", 34, ":"
        DB      OUT_CMD, VAL, 34, "239", 34, ",", VAL, 34, "50", 34, ":"
        DB      OUT_CMD, VAL, 34, "239", 34, ",", VAL, 34, "32", 34, ":"
        DB      OUT_CMD, VAL, 34, "239", 34, ",", VAL, 34, "83", 34, ":"
        DB      OUT_CMD, VAL, 34, "239", 34, ",", VAL, 34, "84", 34, ":"
        DB      OUT_CMD, VAL, 34, "239", 34, ",", VAL, 34, "65", 34, ":"
        DB      OUT_CMD, VAL, 34, "239", 34, ",", VAL, 34, "82", 34, ":"
        DB      OUT_CMD, VAL, 34, "239", 34, ",", VAL, 34, "84", 34, ":"
        DB      OUT_CMD, VAL, 34, "239", 34, ",", VAL, 34, "13", 34, ":"
        DB      OUT_CMD, VAL, 34, "239", 34, ",", VAL, 34, "10", 34, $0D
l11_len EQU     $-l11

        DB      0,20
        DW      l20_len
l20:    DB      RANDOMIZE, USR, "15619", $0E, $00, $00
        DW      15619
        DB      0, $3A, REM, $3A, "LOAD ", 34, "proj112", 34, " CODE 32768", $0D
l20_len EQU     $-l20

        DB      0,21
        DW      l21_len
l21:    DB      OUT_CMD, VAL, 34, "239", 34, ",", VAL, 34, "76", 34, ":"
        DB      OUT_CMD, VAL, 34, "239", 34, ",", VAL, 34, "79", 34, ":"
        DB      OUT_CMD, VAL, 34, "239", 34, ",", VAL, 34, "65", 34, ":"
        DB      OUT_CMD, VAL, 34, "239", 34, ",", VAL, 34, "68", 34, ":"
        DB      OUT_CMD, VAL, 34, "239", 34, ",", VAL, 34, "69", 34, ":"
        DB      OUT_CMD, VAL, 34, "239", 34, ",", VAL, 34, "68", 34, ":"
        DB      OUT_CMD, VAL, 34, "239", 34, ",", VAL, 34, "13", 34, ":"
        DB      OUT_CMD, VAL, 34, "239", 34, ",", VAL, 34, "10", 34, $0D
l21_len EQU     $-l21

        DB      0,30
        DW      l30_len
l30:    DB      OUT_CMD, "239", $0E, $00, $00, $EF, $00, $00, ",", "2", $0E, $00, $00, $02, $00, $00, ":", RANDOMIZE, USR, VAL, 34, "32768", 34, $0D
l30_len EQU     $-l30
        DB      $80
basic_loader_end:

        SAVETRD "project112.TRD","boot.B",basic_loader,basic_loader_end-basic_loader,10
        SAVETRD "project112.TRD","proj112.C",$8000,ProgramEnd112-$8000
