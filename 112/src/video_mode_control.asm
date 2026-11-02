; PROJECT112 MODE CYCLE
; 0 ZX Spectrum 256x192, 1 ATM 640x200, 2 EGA 320x200, 3 text 80x25.
; Space cycles through all four modes and returns to the native Spectrum mode.

SwitchToNextVideoMode:
        LD A,(Current_Mode_Index)
        INC A
        CP 4
        JR C,ModeIndexReady112
        XOR A
ModeIndexReady112:
        LD (Current_Mode_Index),A
        OR A
        JR Z,RestoreSinclairMemoryMap112

        ; ATM video pages: RAM page 5 at $4000, RAM page 1 at $C000.
        LD A,$7A
        LD BC,$7FF7
        OUT (C),A
        LD A,$7E
        LD BC,$FFF7
        OUT (C),A
        JR ApplyVideoRegister112

RestoreSinclairMemoryMap112:
        ; Restore RAM page 0 at $C000. Page 5 remains visible at $4000.
        LD A,$7F
        LD BC,$FFF7
        OUT (C),A
        XOR A
        LD BC,$7FFD
        OUT (C),A

ApplyVideoRegister112:
        LD A,(Current_Mode_Index)
        ADD A,A
        LD E,A
        LD D,0
        LD HL,VideoModeRegisterTable112
        ADD HL,DE
        LD A,(HL)
        OR $C0
        LD BC,$FD77
        OUT (C),A
        LD HL,Debug_ModeApplied112
        CALL DebugPrintString112
        CALL DrawDemoScreen
        JP MainLoop112

VideoModeRegisterTable112:
        DB 3,0
        DB 2,0
        DB 0,0
        DB 6,0
