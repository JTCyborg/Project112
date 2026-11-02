; =========================================================================
; PROJECT112 — ATM TURBO 2+ v7.10 VIDEO MODE TEST
; Target: ATM710 / UnrealSpeccy
; Diagnostic build: Space tests the Sinclair -> ATM 640x200 transition.
; The alias-safe trampoline marks border indices 9 then 10, emits 'R' to #EF,
; then stops. Post-switch execution is deliberately disabled until
; the remapped code/data layout is implemented.
;
; All high-resolution renderers use ATM pages 5 and 1.
; The mode-switch trampoline is in the first 32-byte address-alias-safe
; block at $8000. It never returns through a stack across the mode change.
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
        JP      Init_Z80_System112

ATM_ModeSwitch112:
        ; Preserve the requested video mode across the pre-switch marker.
        ; OUT ($FE),A changes the border before ATM address swapping begins.
        LD      D,A
        LD      A,1
        OUT     ($FE),A
        LD      A,D
        LD      BC,$FD77
        OUT     (C),A
        JP      ATM_ModeReentry112

ATM_ModeReentry112:
        ; The post-switch marker is deliberately inside the same
        ; 32-byte alias-safe region. Border index 10 and 'R' prove execution
        ; continued after the ATM memory address-line swap.
        LD      A,2
        OUT     ($FE),A
        LD      A,'R'
        OUT     (#EF),A
ATM_ModeTransitionHalt112:
        JR      ATM_ModeTransitionHalt112

; -------------------------------------------------------------------------
; Initial setup.
; -------------------------------------------------------------------------
Init_Z80_System112:
        DI
        LD      (Saved_SP_112),SP
        LD      SP,$BFFF

        ; ATM video pages: page 5 at $4000 and page 1 at $C000.
        ; D3=0 (3.5 MHz), D4=0 reserved, D5=0, D7=1 for ATM 7.10.
        LD      A,$11
        LD      BC,$7FFD
        OUT     (C),A

        XOR     A
        LD      (Current_Mode_Index),A
        LD      HL,Debug_RuntimeStart112
        CALL    DebugPrintString112
        JP      ApplyVideoMode

; A stable trampoline jump is used instead of CALL/RET because the ATM
; address bus changes during the write to #FF77.
ApplyVideoMode:
        LD      A,(Current_Mode_Index)
        LD      L,A
        LD      H,0
        LD      DE,ATM_Mode_Bytes112
        ADD     HL,DE
        LD      A,(HL)
        OR      $80
        JP      ATM_ModeSwitch112

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
        LD      A,$11
        LD      BC,$7FFD
        OUT     (C),A
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

Debug_RuntimeStart112: DEFM "PROJECT112 ATM710 START",13,10,0
Debug_ScreenDrawn112:  DEFM "ATM SCREEN DRAWN",13,10,0
Debug_Ready112:        DEFM "ATM VIDEO TEST READY",13,10,0
Debug_SpacePressed112: DEFM "SPACE: NEXT ATM MODE",13,10,0

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
