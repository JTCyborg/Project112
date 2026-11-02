; =========================================================================
; PROJECT112 — VIDEO MODE 3: PENTAGON 16-COLOR
; Pentagon 16col v1.1 memory layout:
;   C000, 4000, E000, 6000 for each byte column, then next column.
; Each of the four regions contributes one 2-pixel pair to an 8-pixel cell.
; The offset inside each 6K region uses the standard Spectrum bitmap layout.
; =========================================================================

ClearVideoMemory_16Color112:
        ; Page 5 is visible at $4000-$7FFF. It contains the 4000/6000 regions.
        LD      HL,$4000
        LD      DE,$4001
        LD      BC,$3FFF
        LD      (HL),0
        LDIR

        ; Page 7 is mapped at $C000 by paging value $17.
        ; Clear the two 6K regions used by 16col; do not touch the gaps.
        LD      HL,$C000
        LD      DE,$C001
        LD      BC,6143
        LD      (HL),0
        LDIR

        LD      HL,$E000
        LD      DE,$E001
        LD      BC,6143
        LD      (HL),0
        LDIR
        RET

RenderGlyph_16Color112:
        ; Absolute raster line Y = character_row*8 + glyph_line (0..191).
        LD      A,(Temp_Y112)
        ADD     A,A
        ADD     A,A
        ADD     A,A
        LD      B,A
        LD      A,(GlyphLine112)
        ADD     A,B
        LD      B,A

        ; Standard Spectrum bitmap address:
        ; H = $40 | ((Y & $C0) >> 3) | (Y & 7)
        ; L = ((Y & $38) << 2) | character_column
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
        OR      L
        LD      L,A
        LD      (ColorOffset112),HL

        ; Four successive regions supply the four 2-pixel pairs
        ; across one 8-pixel character cell.
        LD      A,(Temp_FontByte112)
        LD      (ColorShiftByte112),A
        XOR     A
        LD      (ColorPlaneIndex112),A

ColorPairLoop112:
        ; Take the next two source pixels, left to right.
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

        ; Pentagon 16col interleave order: C000, 4000, E000, 6000.
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
