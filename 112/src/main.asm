; =========================================================================
; PROJECT112 — VIDEO MODE DEMONSTRATOR
; Target: Pentagon 1024 / UnrealSpeccy
; Space: cycle video modes.
; Character test: ASCII 32..127, 16 columns x 6 rows.
; =========================================================================

        DEVICE ZXSPECTRUM128
        EMPTYTRD "project112.TRD"

        ORG     $8000

Init_Z80_System112:
        DI
        LD      (Saved_SP_112),SP
        LD      SP,$7FFF

        ; Map Pentagon screen page 5 at $4000-$7FFF.
        LD      A,$10
        LD      BC,$7FFD
        OUT     (C),A

        XOR     A
        LD      (Current_Mode_Index),A
        CALL    ApplyVideoMode
        CALL    DrawDemoScreen

MainLoop112:
        ; Space is bit 4 of the $7FFE keyboard half-row (active low).
        LD      BC,$7FFE
        IN      A,(C)
        BIT     4,A
        JR      Z,SpacePressed112

        ; Space advances one mode after key release.
        JR      MainLoop112

SpacePressed112:
WaitSpaceRelease112:
        IN      A,(C)
        BIT     4,A
        JR      Z,WaitSpaceRelease112
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
        LD      L,A
        LD      H,0
        LD      DE,Mode_Border_Colors
        ADD     HL,DE
        LD      A,(HL)
        OUT     ($FE),A
        RET

; Clear the full 16K screen window in RAM page 5. This also clears
; the secondary $6000-$77FF plane used by 512x192 / A4B-style modes.
ClearVideoMemory112:
        LD      A,$10
        LD      BC,$7FFD
        OUT     (C),A
        LD      HL,$4000
        LD      DE,$4001
        LD      BC,$3FFF
        LD      (HL),0
        LDIR
        RET

DrawDemoScreen:
        CALL    ClearVideoMemory112

        LD      HL,Text_Title112
        LD      C,0
        LD      D,0
        CALL    PrintString112

        LD      HL,Text_Space112
        LD      C,0
        LD      D,2
        CALL    PrintString112

        LD      HL,Text_Mode112
        LD      C,0
        LD      D,4
        CALL    PrintString112

        ; Print the active mode name.
        LD      A,(Current_Mode_Index)
        LD      L,A
        LD      H,0
        ADD     HL,HL
        LD      DE,Mode_Name_Pointers
        ADD     HL,DE
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        EX      DE,HL
        LD      C,0
        LD      D,5
        CALL    PrintString112

        LD      HL,Text_Charset112
        LD      C,0
        LD      D,7
        CALL    PrintString112

        ; Character matrix: ASCII 32..127, 16 columns x 6 rows.
        LD      A,32
        LD      (Demo_Character112),A
        LD      A,0
        LD      (Demo_Row112),A
DemoRowLoop112:
        LD      A,0
        LD      (Demo_Column112),A
DemoColumnLoop112:
        LD      A,(Demo_Column112)
        LD      C,A
        LD      A,(Demo_Row112)
        ADD     A,8
        LD      D,A
        LD      A,(Demo_Character112)
        CALL    PrintChar112
        LD      A,(Demo_Character112)
        INC     A
        LD      (Demo_Character112),A

        LD      A,(Demo_Column112)
        INC     A
        LD      (Demo_Column112),A
        CP      16
        JR      NZ,DemoColumnLoop112

        LD      A,(Demo_Row112)
        INC     A
        LD      (Demo_Row112),A
        CP      6
        JR      NZ,DemoRowLoop112
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

; Draw one 8x8 glyph. A=ASCII, C=column (0..31), D=row (0..23).
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
        ; Recalculate destination after using HL for the font pointer.
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
        LD      A,(Temp_FontByte112)
        LD      (HL),A
        POP     HL

        LD      A,(GlyphLine112)
        INC     A
        LD      (GlyphLine112),A
        CP      8
        JR      NZ,GlyphLineLoop112

        ; Character attribute: bright ink, black paper, color varies by glyph.
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
        LD      A,(Temp_Character112)
        AND     7
        OR      $40
        LD      (HL),A

        LD      A,(Current_Mode_Byte)
        AND     $20
        JR      Z,PrintCharDone112
        LD      A,H
        ADD     A,$08
        LD      H,A
        LD      A,(Temp_Character112)
        AND     7
        OR      $40
        LD      (HL),A

PrintCharDone112:
        POP     HL
        POP     DE
        POP     BC
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

        ALIGN   256
Font88_112:
        INCBIN  "src/font88.bin"

ProgramEnd112:

; =========================================================================
; TR-DOS BASIC loader
; =========================================================================
        ORG     $B000
CLEAR       EQU $FD
RANDOMIZE   EQU $F9
USR         EQU $C0
REM         EQU $EA

basic_loader:
        DB      0,10
        DW      l10_len
l10:
        DB      CLEAR,"32767",$0E,0,0
        DW      32767
        DB      0,$0D
l10_len EQU $-l10

        DB      0,20
        DW      l20_len
l20:
        DB      RANDOMIZE,USR,"15619",$0E,0,0
        DW      15619
        DB      0
        DB      $3A,REM,$3A
        DB      "LOAD ",34,"proj112",34," CODE 32768",$0D
l20_len EQU $-l20

        DB      0,30
        DW      l30_len
l30:
        DB      RANDOMIZE,USR,"32768",$0E,0,0
        DW      32768
        DB      0,$0D
l30_len EQU $-l30
basic_loader_end:

        SAVETRD "project112.TRD","proj112.B",basic_loader,basic_loader_end-basic_loader,10
        SAVETRD "project112.TRD","proj112.C",$8000,ProgramEnd112-$8000
