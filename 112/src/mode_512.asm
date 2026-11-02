; =========================================================================
; PROJECT112 — VIDEO MODE 1: 512x192
; Even and odd byte columns occupy separate screen halves.
; =========================================================================

ClearVideoMemory_512112:
        LD      A,$10
        LD      BC,$7FFD
        OUT     (C),A
        LD      HL,$4000
        LD      DE,$4001
        LD      BC,$3FFF
        LD      (HL),0
        LDIR
        RET

RenderGlyph_512112:
        LD      A,(Temp_Y112)
        ADD     A,A
        ADD     A,A
        ADD     A,A
        LD      B,A
        LD      A,(GlyphLine112)
        ADD     A,B
        LD      B,A
        LD      A,B
        AND     $C0
        RRCA
        RRCA
        RRCA
        OR      $40
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
        SRL     A
        OR      L
        LD      L,A
        LD      A,(Temp_X112)
        AND     1
        JR      Z,Mode512Store112
        SET     5,H
Mode512Store112:
        LD      A,(Temp_FontByte112)
        LD      (HL),A
        RET

RenderAttributes_512112:
        RET
