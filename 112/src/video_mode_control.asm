; =========================================================================
; PROJECT112 — ATM TURBO 2+ v7.10 VIDEO MODE CONTROL
;
; System register aliases:
;   #FD77 keeps PEN enabled (A8=1) and DOSEN/shadow ports enabled (A9=0).
;   D6=1 disables the 8031; D7=1 is the idle VE0 level.
; RG0..RG2 are D0..D2:
;   2 = 640x200, 0 = EGA 320x200, 6 = text 80x25.
; =========================================================================
SwitchToNextVideoMode:
        LD      A,(Current_Mode_Index)
        INC     A
        CP      4
        JR      C,ATMModeIndexReady112
        LD      A,1
ATMModeIndexReady112:
        LD      (Current_Mode_Index),A
        LD      L,A
        LD      H,0
        LD      DE,ATM_Mode_Bytes112
        ADD     HL,DE
        LD      A,(HL)
        OR      $C0
        LD      BC,$FD77
        OUT     (C),A
        LD      HL,Debug_ModeApplied112
        CALL    DebugPrintString112
        CALL    DrawDemoScreen
        JP      MainLoop112

ATM_Mode_Bytes112:
        DB      3
        DB      2
        DB      0
        DB      6
