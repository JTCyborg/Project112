; =========================================================================
; PROJECT112 — VIDEO MODE CONTROL PIPELINE
; Cyclic mode selection, hardware register and paging setup.
; =========================================================================

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


; Mode-control constants and lookup tables.
Mode_Count             EQU 5
Current_Mode_Byte:     DB 0
Debug_ModeApply112:    DEFM "VIDEO MODE APPLY",13,10,0

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
