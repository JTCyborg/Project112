; =========================================================================
; PROJECT112 — ATM TURBO 2+ v7.10 VIDEO MODE CONTROL
; ATM system port #77, bits D2..D0 select the video mode:
;   3 = Sinclair 256x192
;   2 = 640x200 hardware multicolor
;   0 = 320x200 EGA, 16 colors
;   6 = 80x25 text
;
; D7=1 default on v7.10, D6=1 disables 8031 keyboard MCU,
; D5=1 enables HSYNC interrupt, D4=0 reserved, D3=0 (3.5 MHz).
; =========================================================================

SwitchToNextVideoMode:
        LD      A,(Current_Mode_Index)
        INC     A
        CP      Mode_Count
        JR      C,ATMModeIndexReady112
        XOR     A
ATMModeIndexReady112:
        LD      (Current_Mode_Index),A
        CALL    ApplyVideoMode
        CALL    DrawDemoScreen
        RET

ApplyVideoMode:
        LD      A,(Current_Mode_Index)
        LD      L,A
        LD      H,0
        LD      DE,ATM_Mode_Bytes112
        ADD     HL,DE
        LD      A,(HL)
        OR      $E0
        OUT     ($77),A
        RET

Mode_Count             EQU 4
ATM_Mode_Bytes112:
        DB      3                       ; 0: Sinclair 256x192
        DB      2                       ; 1: 640x200 hardware multicolor
        DB      0                       ; 2: 320x200 EGA 16-color
        DB      6                       ; 3: 80x25 hardware text

Current_Mode_Byte:     DB 0
