; =========================================================================
; PROJECT112 — ATM TURBO 2+ v7.10 VIDEO MODE TEST
; Target: ATM710 / UnrealSpeccy
; Native ATM video test: Space cycles 640x200 -> EGA 320x200 -> 80x25.
; The ATM page dispatcher explicitly maps RAM page 5 into $4000 and page 1
; into $C000. Program code and stack remain in CPU window 2 ($8000-$BFFF).
; All display renderers follow the ATM2+ memory map document in the repo.
; =========================================================================

        DEVICE ZXSPECTRUM128
        EMPTYTRD "project112.TRD"

        ORG     $8000

; -------------------------------------------------------------------------
; ATM address-bus-safe entry/trampoline block.
; ATM 7.10 swaps A5..A7 with A8..A10 between Sinclair and hi-res modes.
; $8000..$801F has matching values in those bit groups.
; Keep this block below 32 bytes and do not move it.
; -------------------------------------------------------------------------
Project112Entry:
        ; First instruction-level proof that BASIC actually entered $8000.
        LD      A,'Z'
        OUT     (#EF),A
        JP      Init_Z80_System112


; -------------------------------------------------------------------------
; Initial setup.
; -------------------------------------------------------------------------
Init_Z80_System112:
        DI
        LD      (Saved_SP_112),SP
        LD      SP,$BFFF

        ; Emit a marker before changing ATM video/address-bus mode.
        LD      HL,Debug_BuildVersion112
        CALL    DebugPrintString112
        LD      HL,Debug_RuntimeStart112
        CALL    DebugPrintString112

        ; Enable ATM shadow ports and select 640x200.
        ; A8=1 (PEN enabled), A9=0 (DOSEN/shadow ports enabled).
        ; D6=1 disables the 8031; D7=1 is the required VE0 idle level.
        LD      A,$C2
        LD      BC,$FD77
        OUT     (C),A

        ; Select memory map 0 and visible screen page 5 (7FFD D3=0).
        ; The ATM dispatcher entries below then define the actual RAM pages.
        XOR     A
        LD      BC,$7FFD
        OUT     (C),A

        ; Map physical video RAM pages through the ATM page dispatcher.
        ; Page 5 -> CPU window $4000-$7FFF; page 1 -> $C000-$FFFF.
        ; D0-D5 are inverted page number, D6=1 selects RAM, D7=0
        ; disables 7FFD mixing for these two fixed video windows.
        LD      A,$7A                 ; ~page 5, RAM, fixed page
        LD      BC,$7FF7
        OUT     (C),A
        LD      A,$7E                 ; ~page 1, RAM, fixed page
        LD      BC,$FFF7
        OUT     (C),A

        ; BASIC selected ATM 640x200 before loading this code.
        LD      A,1
        LD      (Current_Mode_Index),A
        ; Render the actual character-grid test immediately after mapping VRAM.
        ; The raw fill pattern is kept as a callable diagnostic, but must not
        ; replace the normal startup renderer.
        CALL    DrawDemoScreen
        LD      HL,Debug_Ready112
        CALL    DebugPrintString112
        JP      MainLoop112


; -------------------------------------------------------------------------
; ATM 640x200 raw memory diagnostic.
; Writes deterministic full-screen patterns without font, glyph renderer,
; per-character offsets or EGA conversion:
;   page 5 even cells ($4000): $FF
;   page 5 odd  cells ($6000): $00
;   page 1 even attributes ($C000): $47
;   page 1 odd  attributes ($E000): $47
; Each plane is 8000 bytes (200 scanlines * 40 bytes).
; -------------------------------------------------------------------------
ATM640_MemoryPattern112:
        LD      HL,$4000
        LD      A,$FF
        CALL    ATM640_FillPlane112
        LD      HL,$6000
        XOR     A
        CALL    ATM640_FillPlane112
        LD      HL,$C000
        LD      A,$47
        CALL    ATM640_FillPlane112
        LD      HL,$E000
        LD      A,$47
        CALL    ATM640_FillPlane112
        LD      HL,Debug_RawPattern112
        JP      DebugPrintString112

; HL=destination, A=fill byte. Fills exactly 8000 bytes.
ATM640_FillPlane112:
        LD      (HL),A
        PUSH    HL
        POP     DE
        INC     DE
        LD      BC,7999
        LDIR
        RET

; -------------------------------------------------------------------------
; Debug output — UnrealSpeccy diagnostic port #EF.
; HL points to a zero-terminated string. AF and HL are preserved.
; -------------------------------------------------------------------------
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
; Clear active video memory. ATM hi-res modes use page 5 + page 1.
; Sinclair mode clears only the visible bitmap/attribute area in page 5.
; -------------------------------------------------------------------------
ClearVideoMemory112:
        LD      A,(Current_Mode_Index)
        OR      A
        JP      Z,ClearVideoMemory_Standard112
        JP      ClearVideoMemory_ATM112

; -------------------------------------------------------------------------
; Draw the test screen for the selected native ATM mode.
; -------------------------------------------------------------------------
DrawDemoScreen:
        CALL    ClearVideoMemory112
        LD      A,(Current_Mode_Index)
        CP      3
        JR      Z,DrawDemoCharacterGrid112

DrawDemoCharacterGrid112:
        ; Select the character grid geometry for the active ATM mode.
        LD      A,(Current_Mode_Index)
        OR      A
        JR      Z,GridGeometrySinclair112
        CP      2
        JR      Z,GridGeometryEGA112
        ; 640x200 graphics and 80x25 hardware text.
        LD      A,80
        LD      (Grid_Width112),A
        LD      A,25
        LD      (Grid_Height112),A
        JR      GridGeometryReady112

GridGeometrySinclair112:
        LD      A,32
        LD      (Grid_Width112),A
        LD      A,24
        LD      (Grid_Height112),A
        JR      GridGeometryReady112

GridGeometryEGA112:
        LD      A,40
        LD      (Grid_Width112),A
        LD      A,25
        LD      (Grid_Height112),A

GridGeometryReady112:
        ; Row 0 contains the active mode name.
        LD      HL,Text_ModePrefix112
        LD      C,0
        LD      D,0
        CALL    PrintString112
        LD      A,(Current_Mode_Index)
        ADD     A,A
        LD      E,A
        LD      D,0
        LD      HL,Mode_Name_Pointers
        ADD     HL,DE
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        EX      DE,HL
        LD      C,6
        LD      D,0
        CALL    PrintString112

        ; Test area: character ramp, bottom ruler and right ruler.
        LD      A,32
        LD      (Demo_Character112),A
        LD      A,1
        LD      (Demo_Row112),A

DemoRowLoop112:
        XOR     A
        LD      (Demo_Column112),A

DemoColumnLoop112:
        LD      A,(Demo_Column112)
        LD      C,A
        LD      A,(Demo_Row112)
        LD      D,A

        LD      A,(Demo_Row112)
        LD      B,A
        LD      A,(Grid_Height112)
        DEC     A
        CP      B
        JR      Z,DrawBottomRuler112

        LD      A,(Demo_Column112)
        LD      B,A
        LD      A,(Grid_Width112)
        DEC     A
        CP      B
        JR      Z,DrawRightRuler112

        LD      A,(Demo_Character112)
        JR      DrawGridCell112

DrawBottomRuler112:
        LD      A,(Demo_Column112)
        INC     A
        CALL    Modulo10_112
        OR      A
        LD      A,'-'
        JR      NZ,DrawGridCell112
        LD      A,'0'
        JR      DrawGridCell112

DrawRightRuler112:
        LD      A,(Demo_Row112)
        INC     A
        CALL    Modulo10_112
        OR      A
        LD      A,'|'
        JR      NZ,DrawGridCell112
        LD      A,'0'

DrawGridCell112:
        CALL    PrintChar112

        LD      A,(Demo_Character112)
        INC     A
        CP      127
        JR      C,GridCharReady112
        LD      A,32
GridCharReady112:
        LD      (Demo_Character112),A

        LD      A,(Demo_Column112)
        INC     A
        LD      (Demo_Column112),A
        LD      B,A
        LD      A,(Grid_Width112)
        CP      B
        JR      NZ,DemoColumnLoop112

        LD      A,(Demo_Row112)
        INC     A
        LD      (Demo_Row112),A
        LD      B,A
        LD      A,(Grid_Height112)
        CP      B
        JP      NZ,DemoRowLoop112

        LD      HL,Debug_ScreenDrawn112
        CALL    DebugPrintString112
        RET

; Return A = A modulo 10. Preserves BC and DE.
Modulo10_112:
        PUSH    BC
        LD      B,10
Modulo10Loop112:
        CP      B
        JR      C,Modulo10Done112
        SUB     B
        JR      Modulo10Loop112
Modulo10Done112:
        POP     BC
        RET

; Print zero-terminated string at C=column, D=row.
PrintString112:
        LD      A,(HL)
        OR      A
        RET     Z
        PUSH    HL
        CALL    PrintChar112
        POP     HL
        INC     HL
        INC     C
        JR      PrintString112

; A=ASCII character, C=column, D=row.
; Hardware text mode writes character codes directly to ATM character RAM.
; Graphics modes render the supplied 8x8 glyph from Font88_112.
PrintChar112:
        PUSH    BC
        PUSH    DE
        PUSH    HL
        LD      (Temp_Character112),A
        LD      A,C
        LD      (Temp_X112),A
        LD      A,D
        LD      (Temp_Y112),A

        LD      A,(Current_Mode_Index)
        CP      3
        JR      Z,PrintCharATMText112

        LD      A,(Temp_Character112)
        CP      32
        JP      C,PrintCharDone112
        SUB     32
        LD      L,A
        LD      H,0
        ADD     HL,HL
        ADD     HL,HL
        ADD     HL,HL
        LD      DE,Font88_112
        ADD     HL,DE
        LD      (FontPointer112),HL

        XOR     A
        LD      (GlyphLine112),A

GlyphLineLoop112:
        LD      HL,(FontPointer112)
        LD      A,(HL)
        LD      (Temp_FontByte112),A
        INC     HL
        LD      (FontPointer112),HL

        LD      A,(Current_Mode_Index)
        OR      A
        CALL    Z,RenderGlyph_Standard112
        LD      A,(Current_Mode_Index)
        CP      1
        CALL    Z,RenderGlyph_ATM640112
        LD      A,(Current_Mode_Index)
        CP      2
        CALL    Z,RenderGlyph_ATMEGA112

        LD      A,(GlyphLine112)
        INC     A
        LD      (GlyphLine112),A
        CP      8
        JP      NZ,GlyphLineLoop112

        LD      A,(Current_Mode_Index)
        OR      A
        CALL    Z,RenderAttributes_Standard112
        JR      PrintCharDone112

PrintCharATMText112:
        CALL    RenderChar_ATMText112

PrintCharDone112:
        POP     HL
        POP     DE
        POP     BC
        RET

; -------------------------------------------------------------------------
; Native ATM video implementations.
; -------------------------------------------------------------------------
        INCLUDE "src/mode_standard.asm"
        INCLUDE "src/mode_atm.asm"
        INCLUDE "src/video_mode_control.asm"
        INCLUDE "src/keyboard.asm"

; -------------------------------------------------------------------------
; Runtime data.
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

; Bump this identifier whenever a test image/source revision changes.
Debug_BuildVersion112: DEFM "P112 BUILD ATM710-ENTRY-20261103.01",13,10,0
Debug_RuntimeStart112: DEFM "PROJECT112 ATM710 START",13,10,0
Debug_ScreenDrawn112:  DEFM "ATM SCREEN DRAWN",13,10,0
Debug_Ready112:        DEFM "ATM VIDEO TEST READY",13,10,0
Debug_RawPattern112:    DEFM "ATM640 RAW MEMORY PATTERN",13,10,0
Debug_SpacePressed112: DEFM "SPACE: NEXT ATM MODE",13,10,0
Debug_ModeApplied112:  DEFM "ATM MODE APPLIED",13,10,0

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

; EGA byte encoding for two adjacent pixels: left pixel in D0,D1,D2,D6;
; right pixel in D3,D4,D5,D7. Black=0, white=15.
ATM_ColorPairValues112:
        DB      $00,$B8,$47,$FF

; ATM EGA layers: page 1 first half, page 5 first half,
; page 1 second half, page 5 second half.
ATM_EGA_PlaneBases112:
        DW      $C000,$4000,$E000,$6000

        ALIGN   256
Font88_112:
        INCBIN  "src/font88.bin"

ProgramEnd112:

; =========================================================================
; TR-DOS BASIC loader
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
        ; Line 10: OUT 239,1: CLEAR 32767
        DB      0,10
        DW      l10_len
l10:
        DB      OUT_CMD
        DB      "239", $0E, $00, $00, $EF, $00, $00
        DB      ","
        DB      "1", $0E, $00, $00, $01, $00, $00
        DB      ":"
        DB      CLEAR, "32767", $0E, $00, $00, $7F, $FF, $00
        DB      $0D
l10_len EQU     $-l10

        ; Line 11: print P112 START to diagnostic port #EF.
        DB      0,11
        DW      l11_len
l11:
        DB      OUT_CMD, VAL, 34, "239", 34, ",", VAL, 34, "80", 34, ":"
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
        DB      OUT_CMD, VAL, 34, "239", 34, ",", VAL, 34, "10", 34
        DB      $0D
l11_len EQU     $-l11

        ; Line 20: standard TR-DOS loader trampoline.
        ; Keep LOAD after REM exactly as in the proven working Project122
        ; loader: USR 15619 processes the command tail and loads proj112.C.
        DB      0,20
        DW      l20_len
l20:
        DB      RANDOMIZE, USR, "15619", $0E, $00, $00
        DW      15619
        DB      0
        DB      $3A, REM, $3A
        DB      "LOAD ", 34, "proj112", 34, " CODE 32768", $0D
l20_len EQU     $-l20

        ; Line 21: print LOADED after LOAD returns to BASIC.
        DB      0,21
        DW      l21_len
l21:
        DB      OUT_CMD, VAL, 34, "239", 34, ",", VAL, 34, "76", 34, ":"
        DB      OUT_CMD, VAL, 34, "239", 34, ",", VAL, 34, "79", 34, ":"
        DB      OUT_CMD, VAL, 34, "239", 34, ",", VAL, 34, "65", 34, ":"
        DB      OUT_CMD, VAL, 34, "239", 34, ",", VAL, 34, "68", 34, ":"
        DB      OUT_CMD, VAL, 34, "239", 34, ",", VAL, 34, "69", 34, ":"
        DB      OUT_CMD, VAL, 34, "239", 34, ",", VAL, 34, "68", 34, ":"
        DB      OUT_CMD, VAL, 34, "239", 34, ",", VAL, 34, "13", 34, ":"
        DB      OUT_CMD, VAL, 34, "239", 34, ",", VAL, 34, "10", 34
        DB      $0D
l21_len EQU     $-l21

        ; Line 30: mark handoff, then execute at $8000.
        DB      0,30
        DW      l30_len
l30:
        ; Printable handoff marker: if this is absent, BASIC never reached
        ; the USR expression below. Keep it distinct from binary phase 2.
        DB      OUT_CMD, VAL, 34, "239", 34, ",", VAL, 34, "62", 34, ":"
        DB      OUT_CMD
        DB      "239", $0E, $00, $00, $EF, $00, $00
        DB      ","
        DB      "2", $0E, $00, $00, $02, $00, $00
        DB      ":"
        DB      RANDOMIZE, USR, VAL, 34, "32768", 34
        DB      $0D
l30_len EQU     $-l30
        DB      $80             ; End-of-BASIC-program marker.
basic_loader_end:

        SAVETRD "project112.TRD","boot.B",basic_loader,basic_loader_end-basic_loader,10
        SAVETRD "project112.TRD","proj112.C",$8000,ProgramEnd112-$8000
