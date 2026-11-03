; =========================================================================
; PROJECT112 — KEYBOARD POLLING (Sub-module)
; =========================================================================
        LD      BC,$7FFE
        IN      A,(C)
        BIT     0,A
        JR      Z,SpacePressed112
        JR      MainLoop112

SpacePressed112:
WaitSpaceRelease112:
        IN      A,(C)
        BIT     0,A
        JR      Z,WaitSpaceRelease112
        LD      HL,Debug_SpacePressed112
        CALL    DebugPrintString112
        JP      SwitchToNextVideoMode
