; PROJECT112 — native ZX Spectrum 256x192 video driver.
; The standard screen is RAM page 5 at $4000. No ATM page-port writes here.

ClearVideoMemory_Standard112:
        LD HL,$4000
        LD DE,$4001
        LD BC,6911
        XOR A
        LD (HL),A
        LDIR
        RET

RenderGlyph_Standard112:
        ; pixel_y = character_row*8 + glyph_line
        LD A,(Temp_Y112)
        ADD A,A
        ADD A,A
        ADD A,A
        LD B,A
        LD A,(GlyphLine112)
        ADD A,B
        LD B,A

        ; H = $40 | ((pixel_y & $C0) >> 3) | (pixel_y & 7)
        LD A,B
        AND $C0
        RRCA
        RRCA
        RRCA
        LD C,A
        LD A,B
        AND $07
        OR C
        OR $40
        LD H,A

        ; L = ((pixel_y & $38) << 2) | character_column
        LD A,B
        AND $38
        RLCA
        RLCA
        LD L,A
        LD A,(Temp_X112)
        OR L
        LD L,A
        LD A,(Temp_FontByte112)
        LD (HL),A
        RET

RenderAttributes_Standard112:
        LD A,(Temp_Y112)
        LD L,A
        LD H,0
        ADD HL,HL
        ADD HL,HL
        ADD HL,HL
        ADD HL,HL
        ADD HL,HL
        LD DE,$5800
        ADD HL,DE
        LD A,(Temp_X112)
        ADD A,L
        LD L,A
        JR NC,StandardAttrReady112
        INC H
StandardAttrReady112:
        LD A,$47
        LD (HL),A
        RET
