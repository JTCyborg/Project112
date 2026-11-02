; =========================================================================
; PROJECT112 — ATM TURBO 2+ v7.10 VIDEO MODE CONTROL
; #FD77 mode bits D2..D0:
;   3 = Sinclair 256x192
;   2 = ATM 640x200 hardware multicolor
;   0 = ATM EGA 320x200x16
;   6 = ATM 80x25 hardware text
; D3=0 (3.5MHz), D4=0 reserved, D5=0, D6=0, D7=1 on v7.10.
; The transition itself is the fixed safe trampoline at $8003 in main.asm; A9=0 keeps DOSEN enabled.
; =========================================================================
SwitchToNextVideoMode:
        LD      A,(Current_Mode_Index)
        INC     A
        CP      Mode_Count
        JR      C,ATMModeIndexReady112
        XOR     A
ATMModeIndexReady112:
        LD      (Current_Mode_Index),A
        LD      L,A
        LD      H,0
        LD      DE,ATM_Mode_Bytes112
        ADD     HL,DE
        LD      A,(HL)
        OR      $80
        JP      ATM_ModeSwitch112

Mode_Count             EQU 4
ATM_Mode_Bytes112:
        DB      3
        DB      2
        DB      0
        DB      6
