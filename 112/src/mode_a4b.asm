; =========================================================================
; PROJECT112 — VIDEO MODE 2: A4B HARDWARE MULTICOLOR
; Bitmap at $4000-$57FF; one matching attribute byte at $6000-$77FF
; for every bitmap byte.
; =========================================================================

ClearVideoMemory_A4B112:
        LD      A,$10
        LD      BC,$7FFD
        OUT     (C),A
        LD      HL,$4000
        LD      DE,$4001
        LD      BC,$3FFF
        LD      (HL),0
        LDIR
        RET

RenderGlyph_A4B112:
        ; Pixel bitmap uses the standard Spectrum interleaved layout.
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
        ; A4B attribute is offset + $2000 from the bitmap byte.
        LD      DE,$2000
        ADD     HL,DE
        LD      A,$47
        LD      (HL),A
        RET

RenderAttributes_A4B112:
        ; Attributes are emitted per bitmap scanline in RenderGlyph_A4B112.
        RET
