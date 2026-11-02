; =========================================================================
; PROJECT112 — ATM TURBO 2+ v7.10 VIDEO MODE CONTROL
; BASIC enters ATM 640x200 before loading the executable.
; Space cycles through ATM modes 640x200, EGA 320x200 and 80x25.
; All three modes have D0=0, so no RAM content permutation is triggered.
; Sinclair mode (D0=1) is excluded until a ROM-mediated transition/reload
; path is implemented.
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
        OR      $80
        LD      BC,$FD77
        OUT     (C),A
        LD      HL,Debug_ModeApplied112
        CALL    DebugPrintString112
        CALL    DrawDemoScreen
        JP      MainLoop112

Mode_Count             EQU 3
ATM_Mode_Bytes112:
        DB      3
        DB      2
        DB      0
        DB      6
