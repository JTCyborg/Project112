; =========================================================================
; PROJECT112 — ATM MODE 0: SINCLAIR 256x192
; Bitmap at $4000; attributes at $5800. Page 5 remains visible at $4000.
; =========================================================================
ClearVideoMemory_Standard112:
        LD      A,$11
        LD      BC,$7FFD
        OUT     (C),A
        LD      HL,$4000
        LD      DE,$4001
        LD      BC,6911
        LD      (HL),0
        LDIR
        RET

RenderGlyph_Standard112:
        LD      A,(Temp_Y112)
        AND     $18
        OR      $40
        LD      H,A
        LD      A,(GlyphLine112)
        OR      H
        LD      H,A
        LD      A,(Temp_Y112)
        AND     7
        RLCA
        RLCA
        RLCA
        RLCA
        RLCA
        LD      L,A
        LD      A,(Temp_X112)
        OR      L
        LD      L,A
        LD      A,(Temp_FontByte112)
        LD      (HL),A
        RET

RenderAttributes_Standard112:
        LD      A,(Temp_Y112)
        LD      L,A
        LD      H,0
        ADD     HL,HL
        ADD     HL,HL
        ADD     HL,HL
        ADD     HL,HL
        ADD     HL,HL
        LD      DE,$5800
        ADD     HL,DE
        LD      A,(Temp_X112)
        ADD     A,L
        LD      L,A
        JR      NC,StandardAttrReady112
        INC     H
StandardAttrReady112:
        LD      A,$47
        LD      (HL),A
        RET
