; =========================================================================
; PROJECT112 — VIDEO MODE 3: PENTAGON 16-COLOR
; Four interleaved 6K memory areas: $C000, $4000, $E000, $6000.
; Each byte represents two adjacent pixels.
; =========================================================================

ClearVideoMemory_16Color112:
        LD      A,$10
        LD      BC,$7FFD
        OUT     (C),A
        LD      HL,$4000
        LD      DE,$4001
        LD      BC,$3FFF
        LD      (HL),0
        LDIR
        LD      HL,$C000
        LD      DE,$C001
        LD      BC,$17FF
        LD      (HL),0
        LDIR
        LD      HL,$E000
        LD      DE,$E001
        LD      BC,$17FF
        LD      (HL),0
        LDIR
        RET

RenderGlyph_16Color112:
        LD      A,(Temp_Y112)
        ADD     A,A
        ADD     A,A
        ADD     A,A
        LD      B,A
        LD      A,(GlyphLine112)
        ADD     A,B
        LD      B,A
        ; Spectrum bitmap interleave within each 6K bank.
        LD      A,B
        AND     $C0
        RRCA
        RRCA
        RRCA
        AND     $18
        LD      H,A
        LD      A,B
        AND     7
        OR      H
        LD      H,A
        LD      A,B
        AND     $38
        RLCA
        RLCA
        LD      L,A
        LD      A,(Temp_X112)
        ADD     A,L
        LD      L,A
        JR      NC,ColorOffsetReady112
        INC     H
ColorOffsetReady112:
        LD      (ColorOffset112),HL
        LD      A,(Temp_FontByte112)
        LD      (ColorShiftByte112),A
        XOR     A
        LD      (ColorPlaneIndex112),A
ColorPairLoop112:
        LD      A,(ColorShiftByte112)
        RLCA
        RLCA
        LD      (ColorShiftByte112),A
        AND     3
        LD      E,A
        LD      D,0
        LD      HL,ColorPairValues112
        ADD     HL,DE
        LD      A,(HL)
        LD      (ColorByte112),A
        LD      A,(ColorPlaneIndex112)
        ADD     A,A
        LD      E,A
        LD      D,0
        LD      HL,ColorPlaneBases112
        ADD     HL,DE
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        EX      DE,HL
        LD      DE,(ColorOffset112)
        ADD     HL,DE
        LD      A,(ColorByte112)
        LD      (HL),A
        LD      A,(ColorPlaneIndex112)
        INC     A
        LD      (ColorPlaneIndex112),A
        CP      4
        JP      NZ,ColorPairLoop112
        RET

RenderAttributes_16Color112:
        RET
