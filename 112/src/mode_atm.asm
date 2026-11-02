; =========================================================================
; PROJECT112 — NATIVE ATM TURBO 2+ v7.10 VIDEO MEMORY
; Pages: page 5 at $4000, page 1 at $C000.
; 640x200 and 80x25 split even/odd columns into the two 8K halves.
; EGA 320x200x16 uses four 8K layers:
; $C000, $4000, $E000, $6000. Each layer is 40*200 bytes.
; =========================================================================
ClearVideoMemory_ATM112:
        LD      A,$11
        LD      BC,$7FFD
        OUT     (C),A
        LD      HL,$4000
        LD      DE,$4001
        LD      BC,$3FFF
        LD      (HL),0
        LDIR
        LD      HL,$C000
        LD      DE,$C001
        LD      BC,$3FFF
        LD      (HL),0
        LDIR
        RET

; ATM 640x200: bitmap page5, attributes page1, 40 bytes per scanline.
RenderGlyph_ATM640112:
        CALL    ATM_CalcPixelOffset112
        LD      A,(Temp_X112)
        AND     1
        LD      (ATM_Parity112),A
        LD      HL,(ATM_Offset112)
        LD      DE,$4000
        LD      A,(ATM_Parity112)
        OR      A
        JR      Z,ATM640PixelBaseReady112
        LD      DE,$6000
ATM640PixelBaseReady112:
        ADD     HL,DE
        LD      A,(Temp_FontByte112)
        LD      (HL),A
        LD      HL,(ATM_Offset112)
        LD      DE,$C000
        LD      A,(ATM_Parity112)
        OR      A
        JR      Z,ATM640AttrBaseReady112
        LD      DE,$E000
ATM640AttrBaseReady112:
        ADD     HL,DE
        LD      A,$47
        LD      (HL),A
        RET

; ATM EGA 320x200x16: four 2-pixel pairs per 8-pixel glyph.
RenderGlyph_ATMEGA112:
        CALL    ATM_CalcEGARowOffset112
        ; One byte per character column in each of the four interleaved layers.
        LD      A,(Temp_X112)
        LD      E,A
        LD      D,0
        LD      HL,(ATM_Offset112)
        ADD     HL,DE
        LD      (ATM_Offset112),HL
        LD      A,(Temp_FontByte112)
        LD      (ColorShiftByte112),A
        XOR     A
        LD      (ColorPlaneIndex112),A
ATM_EGAPairLoop112:
        LD      A,(ColorShiftByte112)
        RLCA
        RLCA
        LD      (ColorShiftByte112),A
        AND     3
        LD      E,A
        LD      D,0
        LD      HL,ATM_ColorPairValues112
        ADD     HL,DE
        LD      A,(HL)
        LD      (ColorByte112),A
        LD      A,(ColorPlaneIndex112)
        ADD     A,A
        LD      E,A
        LD      D,0
        LD      HL,ATM_EGA_PlaneBases112
        ADD     HL,DE
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        EX      DE,HL
        LD      DE,(ATM_Offset112)
        ADD     HL,DE
        LD      A,(ColorByte112)
        LD      (HL),A
        LD      A,(ColorPlaneIndex112)
        INC     A
        LD      (ColorPlaneIndex112),A
        CP      4
        JR      NZ,ATM_EGAPairLoop112
        RET

; ATM 80x25 hardware text: character codes in page5, attributes in page1.
RenderChar_ATMText112:
        CALL    ATM_CalcTextOffset112
        LD      A,(Temp_X112)
        AND     1
        LD      (ATM_Parity112),A
        LD      HL,(ATM_Offset112)
        LD      DE,$4000
        LD      A,(ATM_Parity112)
        OR      A
        JR      Z,ATMTextCharBaseReady112
        LD      DE,$6000
ATMTextCharBaseReady112:
        ADD     HL,DE
        LD      A,(Temp_Character112)
        LD      (HL),A
        LD      HL,(ATM_Offset112)
        LD      DE,$C000
        LD      A,(ATM_Parity112)
        OR      A
        JR      Z,ATMTextAttrBaseReady112
        LD      DE,$E000
ATMTextAttrBaseReady112:
        ADD     HL,DE
        LD      A,$47
        LD      (HL),A
        RET

; Pixel offset for 640x200: (character_row*8 + glyph_line)*40 + col/2.
ATM_CalcPixelOffset112:
        LD      A,(Temp_Y112)
        ADD     A,A
        ADD     A,A
        ADD     A,A
        LD      B,A
        LD      A,(GlyphLine112)
        ADD     A,B
        CALL    ATM_CalcYTimes40Only112
        JR      ATM_AddHalfColumn112

; Text offset: character_row*40 + col/2.
ATM_CalcTextOffset112:
        LD      A,(Temp_Y112)
        CALL    ATM_CalcYTimes40Only112
        JR      ATM_AddHalfColumn112

; EGA has one byte per character column in each layer: row*40 + col.
ATM_CalcEGARowOffset112:
        LD      A,(Temp_Y112)
        ADD     A,A
        ADD     A,A
        ADD     A,A
        LD      B,A
        LD      A,(GlyphLine112)
        ADD     A,B
        JP      ATM_CalcYTimes40Only112

ATM_AddHalfColumn112:
        LD      A,(Temp_X112)
        SRL     A
        LD      E,A
        LD      D,0
        LD      HL,(ATM_Offset112)
        ADD     HL,DE
        LD      (ATM_Offset112),HL
        RET

; A*40 = A*5*8. Stores the row offset without a column term.
ATM_CalcYTimes40Only112:
        LD      E,A
        LD      D,0
        LD      L,A
        LD      H,0
        ADD     HL,HL
        ADD     HL,HL
        ADD     HL,DE
        ADD     HL,HL
        ADD     HL,HL
        ADD     HL,HL
        LD      (ATM_Offset112),HL
        RET
