; =========================================================================
<<<<<<< HEAD
; PROJECT112 — KEYBOARD POLLING (Sub-module)
; =========================================================================
=======
; PROJECT112 — KEYBOARD POLLING
; Space: keyboard row $7FFE, bit 0, active low.
; =========================================================================
MainLoop112:
>>>>>>> f8f5905ba455aa6029ffa95e58d48fa5c5a90e7e
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
