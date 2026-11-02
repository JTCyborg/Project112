; =========================================================================
; PROJECT112 — VIDEO MODE DEMONSTRATOR
; Target: Pentagon 1024 / UnrealSpeccy
; Space: cycle video modes.
; Character test: full-screen grid; geometry follows selected mode.
; =========================================================================

        DEVICE ZXSPECTRUM128
        EMPTYTRD "project112.TRD"

        ORG     $8000

Init_Z80_System112:
        DI
        LD      (Saved_SP_112),SP
        ; Keep the stack outside $4000-$7FFF: ClearVideoMemory112
        ; clears the entire screen bank and must never overwrite return addresses.
        LD      SP,$BFFF

        ; Map Pentagon screen page 5 at $4000-$7FFF.
        LD      A,$10
        LD      BC,$7FFD
        OUT     (C),A

        XOR     A
        LD      (Current_Mode_Index),A
        LD      HL,Debug_RuntimeStart112
        CALL    DebugPrintString112
        CALL    ApplyVideoMode
        CALL    DrawDemoScreen
        LD      HL,Debug_Ready112
        CALL    DebugPrintString112



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

; Clear the full 16K screen window in RAM page 5. This also clears
; the secondary $6000-$77FF plane used by 512x192 / A4B-style modes.
ClearVideoMemory112:
        ; Mode-specific screen-memory clearing lives in the corresponding
        ; mode module. The common entry point only dispatches.
        LD      A,(Current_Mode_Index)
        CP      0
        JP      Z,ClearVideoMemory_Standard112
        CP      1
        JP      Z,ClearVideoMemory_512112
        CP      2
        JP      Z,ClearVideoMemory_A4B112
        CP      3
        JP      Z,ClearVideoMemory_16Color112
        JP      ClearVideoMemory_384112

DrawDemoScreen:
        CALL    ClearVideoMemory112

        ; Select the actual character grid for the active video mode.
        LD      A,(Current_Mode_Index)
        CP      1
        JR      Z,GridWidth64_112
        CP      4
        JR      Z,GridGeometry384_112
        LD      A,32
        LD      (Grid_Width112),A
        LD      A,24
        LD      (Grid_Height112),A
        JR      GridGeometryReady112
GridWidth64_112:
        LD      A,64
        LD      (Grid_Width112),A
        LD      A,24
        LD      (Grid_Height112),A
        JR      GridGeometryReady112
GridGeometry384_112:
        LD      A,48
        LD      (Grid_Width112),A
        LD      A,38
        LD      (Grid_Height112),A
GridGeometryReady112:

        ; Reserve row 0 for an explicit active-mode label.
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

        ; Draw the test area. Row 0 is the mode label; the last row
        ; and last column are rulers with a zero marker every 10 cells.
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

        ; The tenth, twentieth, thirtieth... ruler positions are marked '0'.
        ; All other horizontal ruler cells are '-', vertical cells are '|'.
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
        LD      B,A
        LD      A,B
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
        CP      128
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
        JR      NZ,DemoRowLoop112
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

; Print zero-terminated string at C=character column, D=character row.
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

; Draw one 8x8 glyph. A=ASCII, C=column, D=character row.
; Mode-specific bitmap and attribute operations are delegated to mode files.
PrintChar112:
        PUSH    BC
        PUSH    DE
        PUSH    HL
        LD      (Temp_Character112),A
        LD      A,C
        LD      (Temp_X112),A
        LD      A,D
        LD      (Temp_Y112),A

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
        ; Dispatch one scanline to the active mode's independent renderer.
        LD      A,(Current_Mode_Index)
        CP      0
        CALL    Z,RenderGlyph_Standard112
        LD      A,(Current_Mode_Index)
        CP      1
        CALL    Z,RenderGlyph_512112
        LD      A,(Current_Mode_Index)
        CP      2
        CALL    Z,RenderGlyph_A4B112
        LD      A,(Current_Mode_Index)
        CP      3
        CALL    Z,RenderGlyph_16Color112
        LD      A,(Current_Mode_Index)
        CP      4
        CALL    Z,RenderGlyph_384112

        LD      A,(GlyphLine112)
        INC     A
        LD      (GlyphLine112),A
        CP      8
        JP      NZ,GlyphLineLoop112

        ; Character-level attributes are also mode-owned.
        LD      A,(Current_Mode_Index)
        CP      0
        CALL    Z,RenderAttributes_Standard112
        LD      A,(Current_Mode_Index)
        CP      1
        CALL    Z,RenderAttributes_512112
        LD      A,(Current_Mode_Index)
        CP      2
        CALL    Z,RenderAttributes_A4B112
        LD      A,(Current_Mode_Index)
        CP      3
        CALL    Z,RenderAttributes_16Color112
        LD      A,(Current_Mode_Index)
        CP      4
        CALL    Z,RenderAttributes_384112

PrintCharDone112:
        POP     HL
        POP     DE
        POP     BC
        RET

; -------------------------------------------------------------------------
; Independent video-mode implementations.
; Keep mode-specific memory maps, clearing and glyph rendering in these files.
; -------------------------------------------------------------------------
        INCLUDE "src/mode_standard.asm"
        INCLUDE "src/mode_512.asm"
        INCLUDE "src/mode_a4b.asm"
        INCLUDE "src/mode_16color.asm"
        INCLUDE "src/mode_384.asm"
        INCLUDE "src/video_mode_control.asm"
        INCLUDE "src/keyboard.asm"

; -------------------------------------------------------------------------
; Data
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
ColorOffset112:        DW 0
ColorShiftByte112:    DB 0
ColorPlaneIndex112:   DB 0
ColorByte112:         DB 0

Debug_RuntimeStart112: DEFM "P112 RUNNING",13,10,0
Debug_ScreenDrawn112:  DEFM "SCREEN DRAWN",13,10,0
Debug_Ready112:        DEFM "VIDEO TEST READY",13,10,0

Text_ModePrefix112:   DEFM "MODE: ",0

Mode_Name_Pointers:
        DW ModeName_Standard112
        DW ModeName_512112
        DW ModeName_HardwareMC112
        DW ModeName_16Color112
        DW ModeName_384112

ModeName_Standard112:  DEFM "STANDARD 256x192",0
ModeName_512112:       DEFM "512x192",0
ModeName_HardwareMC112:DEFM "A4B MULTICOLOR",0
ModeName_16Color112:   DEFM "16-COLOR 2PX/BYTE",0
ModeName_384112:       DEFM "PENTAGON 384x304",0


; Index is the two adjacent glyph pixels: left in bit 1, right in bit 0.
; White=15, black=0, encoded with Pentagon 16-color component wiring.
ColorPairValues112:
        DB      $00,$B8,$47,$FF
ColorPlaneBases112:
        DW      $C000,$4000,$E000,$6000

        ALIGN   256
Font88_112:
        INCBIN  "src/font88.bin"

ProgramEnd112:

; =========================================================================
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
        DB      0,10
        DW      l10_len
l10:
        DB      CLEAR, "32767", $0E, 0, 0
        DW      32767
        DB      0, $0D
l10_len EQU     $-l10

        DB      0,20
        DW      l20_len
l20:
        DB      RANDOMIZE, USR, "15619", $0E, 0, 0
        DW      15619
        DB      0
        DB      $3A, REM, $3A
        DB      "LOAD ", 34, "proj112", 34, " CODE 32768", $0D
l20_len EQU     $-l20

        DB      0,30
        DW      l30_len
l30:
        DB      RANDOMIZE,USR,"32768",$0E,0,0
        DW      32768
        DB      0, $0D
l30_len EQU     $-l30
basic_loader_end:

        SAVETRD "project112.TRD","proj112.B",basic_loader,basic_loader_end-basic_loader,10
        SAVETRD "project112.TRD","proj112.C",$8000,ProgramEnd112-$8000
