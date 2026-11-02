; =========================================================================
; PROJECT112 — KEYBOARD POLLING MODULE
; Space: keyboard row $7FFE, bit 0, active low.
; Waits for release to prevent repeated mode changes while held.
; =========================================================================

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

; Keyboard module debug text.
Debug_SpacePressed112: DEFM "SPACE PRESSED",13,10,0
