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

MainLoop112:
        ; Space is bit 0 of keyboard row $7FFE (active low).
        LD      BC,$7FFE
        IN      A,(C)
        BIT     0,A
        JR      Z,SpacePressed112

        ; Space advances one mode after key release.
        JR      MainLoop112

SpacePressed112:
WaitSpaceRelease112:
        IN      A,(C)
        BIT     0,A
        JR      Z,WaitSpaceRelease112
        LD      HL,Debug_SpacePressed112
        CALL    DebugPrintString112
        CALL    SwitchToNextVideoMode
        JR      MainLoop112

SwitchToNextVideoMode:
        LD      A,(Current_Mode_Index)
        INC     A
        CP      Mode_Count
        JR      C,ModeIndexReady112
        XOR     A
ModeIndexReady112:
        LD      (Current_Mode_Index),A
        CALL    ApplyVideoMode
        CALL    DrawDemoScreen
        RET

ApplyVideoMode:
        LD      HL,Debug_ModeApply112
        CALL    DebugPrintString112
        LD      A,(Current_Mode_Index)
        LD      L,A
        LD      H,0
        LD      DE,Mode_Hardware_Bytes
        ADD     HL,DE
        LD      A,(HL)
        LD      (Current_Mode_Byte),A
        LD      BC,$EFF7
        OUT     (C),A

        LD      A,(Current_Mode_Index)
        CP      4
        LD      A,$10
        JR      NZ,ModePageReady112
        LD      A,$04
ModePageReady112:
        LD      BC,$7FFD
        OUT     (C),A

        LD      A,(Current_Mode_Index)
        LD      L,A
        LD      H,0
        LD      DE,Mode_Border_Colors
        ADD     HL,DE
        LD      A,(HL)
        OUT     ($FE),A
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

; Clear the full 16K screen window in RAM page 5. This also clears
; the secondary $6000-$77FF plane used by 512x192 / A4B-style modes.
ClearVideoMemory112:
        LD      A,(Current_Mode_Index)
        CP      4
        LD      A,$10
        JR      NZ,ClearPageSelect112
        LD      A,$04
ClearPageSelect112:
        LD      BC,$7FFD
        OUT     (C),A
        LD      HL,$4000
        LD      DE,$4001
        LD      BC,$3FFF
        LD      (HL),0
        LDIR

        LD      A,(Current_Mode_Index)
        CP      4
        JR      Z,Clear384UpperBank112
        CP      3
        JR      Z,Clear16ColorPlanes112
        RET

Clear384UpperBank112:
        ; 384x304 uses RAM page 4 at C000-FFFF and page 5 at 4000-7FFF.
        LD      HL,$C000
        LD      DE,$C001
        LD      BC,$3FFF
        LD      (HL),0
        LDIR
        RET

Clear16ColorPlanes112:
        ; 16-color uses the two 6144-byte regions in selected RAM bank 0.
        LD      HL,$C000
        LD      DE,$C001
        LD      BC,$17FF
        LD      (HL),0
        LDIR
        LD      HL,$E000
        LD      DE,$E001
        LD      BC,$17FF
        LD      (HL),0
        LDIR
        RET

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

        ; Draw every cell. The final row and column are explicit rulers.
        LD      A,32
        LD      (Demo_Character112),A
        XOR     A
        LD      (Demo_Row112),A
DemoRowLoop112:
        XOR     A
        LD      (Demo_Column112),A
DemoColumnLoop112:
        LD      A,(Demo_Column112)
        LD      C,A
        LD      A,(Demo_Row112)
        LD      D,A

        ; Right edge = vertical ruler, bottom edge = horizontal ruler.
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
        LD      A,'-'
        LD      B,C
        LD      A,(Grid_Width112)
        DEC     A
        CP      B
        LD      A,'-'
        JR      NZ,DrawGridCell112
        LD      A,'+'
        JR      DrawGridCell112
DrawRightRuler112:
        LD      A,'|'
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
; The 8x8 font is stored as 96 consecutive glyphs for ASCII 32..127.
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
        PUSH    HL
        ; Recalculate destination for the selected bitmap organization.
        LD      A,(Current_Mode_Index)
        CP      4
        JR      Z,PrintGlyph384_112
        CP      3
        JR      Z,PrintGlyph16Color112
        CP      1
        JR      Z,PrintGlyph512_112
        ; Standard 256x192 bitmap (also the pixel plane of A4B).
        LD      HL,0
        LD      A,(Temp_Y112)
        AND     $18
        OR      $40
        LD      H,A
        LD      A,(GlyphLine112)
        OR      H
        LD      H,A
        LD      A,(Temp_Y112)
        AND     7
        RLCA
        RLCA
        RLCA
        RLCA
        RLCA
        LD      L,A
        LD      A,(Temp_X112)
        OR      L
        LD      L,A
        JP      PrintGlyphStore112

PrintGlyph384_112:
        ; Canonical 384x304 XYSC384 mapping. Y is a 0..303 scanline,
        ; E is the 0..47 byte column; page 4 must be mapped at C000.
        LD      A,(Temp_Y112)
        LD      C,A
        LD      B,0
        SLA     C
        RL      B
        SLA     C
        RL      B
        SLA     C
        RL      B
        LD      A,(GlyphLine112)
        ADD     A,C
        LD      C,A
        JR      NC,Print384YReady112
        INC     B
Print384YReady112:
        LD      A,(Temp_X112)
        LD      E,A
        CALL    XYSC384_112
        LD      A,(Temp_FontByte112)
        LD      (HL),A
        POP     HL
        JP      PrintGlyphLineStored112

PrintGlyph16Color112:
        ; 16-color mode stores four 2-pixel color bytes per character scanline.
        ; Plane bases are C000, 4000, E000 and 6000 (6144 bytes each).
        LD      A,(Temp_Y112)
        ADD     A,A
        ADD     A,A
        ADD     A,A
        LD      B,A
        LD      A,(GlyphLine112)
        ADD     A,B
        LD      B,A
        LD      A,B
        RRCA
        RRCA
        RRCA
        AND     $1F
        LD      H,A
        LD      A,B
        ADD     A,A
        ADD     A,A
        ADD     A,A
        ADD     A,A
        ADD     A,A
        LD      L,A
        LD      A,(Temp_X112)
        ADD     A,L
        LD      L,A
        JR      NC,ColorOffsetReady112
        INC     H
ColorOffsetReady112:
        LD      (ColorOffset112),HL
        LD      A,(Temp_FontByte112)
        LD      (ColorShiftByte112),A
        XOR     A
        LD      (ColorPlaneIndex112),A
ColorPairLoop112:
        LD      A,(ColorShiftByte112)
        RLCA
        RLCA
        LD      (ColorShiftByte112),A
        AND     3
        LD      E,A
        LD      D,0
        LD      HL,ColorPairValues112
        ADD     HL,DE
        LD      A,(HL)
        LD      (ColorByte112),A

        LD      A,(ColorPlaneIndex112)
        ADD     A,A
        LD      E,A
        LD      D,0
        LD      HL,ColorPlaneBases112
        ADD     HL,DE
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        EX      DE,HL
        LD      DE,(ColorOffset112)
        ADD     HL,DE
        LD      A,(ColorByte112)
        LD      (HL),A

        LD      A,(ColorPlaneIndex112)
        INC     A
        LD      (ColorPlaneIndex112),A
        CP      4
        JR      NZ,ColorPairLoop112
        POP     HL
        JR      PrintGlyphLineStored112

PrintGlyph512_112:
        ; 512x192: even and odd byte columns are stored in separate
        ; 16K screen halves. Each half receives byte index column/2.
        LD      A,(Temp_Y112)
        ADD     A,A
        ADD     A,A
        ADD     A,A
        LD      B,A
        LD      A,(GlyphLine112)
        ADD     A,B
        LD      B,A
        LD      A,B
        AND     $C0
        RRCA
        RRCA
        RRCA
        OR      $40
        LD      H,A
        LD      A,B
        AND     7
        OR      H
        LD      H,A
        LD      A,B
        AND     $38
        RLCA
        RLCA
        LD      L,A
        LD      A,(Temp_X112)
        SRL     A
        OR      L
        LD      L,A
        LD      A,(Temp_X112)
        AND     1
        JR      Z,PrintGlyphStore112
        SET     5,H
PrintGlyphStore112:
        LD      A,(Temp_FontByte112)
        LD      (HL),A
        POP     HL
PrintGlyphLineStored112:
        LD      A,(GlyphLine112)
        INC     A
        LD      (GlyphLine112),A
        CP      8
        JR      NZ,GlyphLineLoop112

        ; 512x192 and 16-color modes have no Spectrum attribute plane.
        LD      A,(Current_Mode_Index)
        CP      1
        JR      Z,PrintCharDone112
        CP      3
        JR      Z,PrintCharDone112
        CP      4
        JR      Z,Print384Attribute112

        ; Character attribute: bright white ink on black paper for every glyph.
        ; Standard mode uses $5800; hardware multicolor uses its $6000 plane.
        LD      A,(Temp_Y112)
        LD      L,A
        LD      H,0
        ADD     HL,HL
        ADD     HL,HL
        ADD     HL,HL
        ADD     HL,HL
        ADD     HL,HL
        LD      DE,$5800
        ADD     HL,DE
        LD      A,(Temp_X112)
        ADD     A,L
        LD      L,A
        JR      NC,AttrAddressReady112
        INC     H
AttrAddressReady112:
        LD      A,$47                 ; BRIGHT white ink, black paper
        LD      (HL),A

        LD      A,(Current_Mode_Byte)
        AND     $20
        JR      Z,PrintCharDone112
        LD      A,H
        ADD     A,$08
        LD      H,A
        LD      A,$47                 ; BRIGHT white ink, black paper
        LD      (HL),A

        JR      PrintCharDone112

Print384Attribute112:
        ; Attribute address is derived from the 384x304 bitmap address.
        LD      A,(Temp_Y112)
        ADD     A,A
        ADD     A,A
        ADD     A,A
        LD      C,A
        LD      B,0
        LD      A,(Temp_X112)
        LD      E,A
        CALL    XYSC384_112
        CALL    SA384_112
        LD      A,$47
        LD      (HL),A

PrintCharDone112:
        POP     HL
        POP     DE
        POP     BC
        RET

; -------------------------------------------------------------------------
; Pentagon 384x304 address helpers, transcribed from Video/ig7m384p (1).htm.
; XYSC input: BC=scanline 0..303, E=byte column 0..47; output HL=bitmap byte.
; SA input/output: HL bitmap address -> corresponding attribute address.
; -------------------------------------------------------------------------
XYSC384_112:
        CALL    YSC384_112
        LD      A,E
        SUB     8
        JR      C,XS384Left112
        CP      32
        JR      C,XS384Middle112
        SUB     32+$18
XS384Left112:
        ADD     A,8+$18
        JR      XS384Add112
XS384Middle112:
        SET     5,H
XS384Add112:
        ADD     A,L
        LD      L,A
        RET

YSC384_112:
        LD      A,C
        AND     7
        LD      H,A
        XOR     C
        ADD     A,A
        ADD     A,A
        ADD     A,A
        ADD     A,A
        LD      L,A
        LD      A,$D8
        INC     B
        DJNZ    YSC384Low112
        LD      A,C
        AND     $C0
        RRCA
        RRCA
        RRCA
        JR      NZ,YSC384NoWrap112
        LD      A,$C0-$38
        ADD     A,$38
        JR      YSC384Low112
YSC384NoWrap112:
        ADD     A,H
        LD      H,A
        RET
YSC384Low112:
        ADD     A,H
        LD      H,A
        RET

SA384_112:
        LD      A,H
        AND     $D8
        JP      P,SA384Positive112
        ADD     A,$86-$C0-$C2+$40
SA384Positive112:
        ADD     A,$C2-$40
        RRCA
        RRCA
        RRCA
        XOR     H
        AND     $DF
        XOR     H
        LD      H,A
        RET

; -------------------------------------------------------------------------
; Data
; -------------------------------------------------------------------------
Mode_Count             EQU 5
Saved_SP_112:          DW 0
Current_Mode_Index:    DB 0
Current_Mode_Byte:     DB 0
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
Debug_ModeApply112:    DEFM "VIDEO MODE APPLY",13,10,0
Debug_ScreenDrawn112:  DEFM "SCREEN DRAWN",13,10,0
Debug_Ready112:        DEFM "VIDEO TEST READY",13,10,0
Debug_SpacePressed112: DEFM "SPACE PRESSED",13,10,0

Text_Title112:         DEFM "PROJECT112 VIDEO MODE TEST",0
Text_Space112:         DEFM "PRESS SPACE TO CHANGE MODE",0
Text_Mode112:          DEFM "ACTIVE #EFF7 MODE:",0
Text_Charset112:       DEFM "ASCII TEST: 32-127",0

Mode_Name_Pointers:
        DW ModeName_Standard112
        DW ModeName_512112
        DW ModeName_HardwareMC112
        DW ModeName_16Color112
        DW ModeName_384112

ModeName_Standard112:  DEFM "STANDARD 256x192",0
ModeName_512112:       DEFM "512x192 EXTENDED",0
ModeName_HardwareMC112:DEFM "HARDWARE MULTICOLOR (A4B)",0
ModeName_16Color112:   DEFM "16-COLOR / 2 PIXELS PER BYTE",0
ModeName_384112:       DEFM "PENTAGON 384x304",0

; UnrealSpeccy / Pentagon 1024 mode bits:
; D0=16-color, D1=512x192, D5=hardware multicolor, D6=384x304.
Mode_Hardware_Bytes:
        DB      $00
        DB      $02
        DB      $20
        DB      $01
        DB      $40

Mode_Border_Colors:
        DB      1,2,4,5,6

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
