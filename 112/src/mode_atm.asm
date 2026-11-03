; =========================================================================
; PROJECT112 — ATM TURBO 2+ v7.10 VIDEO MEMORY
;
; Physical RAM page mapping is configured once in main.asm:
;   CPU $4000-$7FFF -> RAM page 5
;   CPU $C000-$FFFF -> RAM page 1
;
; ATM video controller fetches page 5/page 1 in four 8K video regions.
; All offsets below are relative to the corresponding 16K page.
; =========================================================================

ClearVideoMemory_ATM112:
        ; Clear both mapped physical video pages. Keep the program and stack
        ; in window 2 ($8000-$BFFF), which is not touched here.
        LD      HL,$4000
        LD      DE,$4001
        LD      BC,$3FFF
        XOR     A
        LD      (HL),A
        LDIR
        LD      HL,$C000
        LD      DE,$C001
        LD      BC,$3FFF
        XOR     A
        LD      (HL),A
        LDIR
        RET

; -------------------------------------------------------------------------
; ATM 640x200: 40 bytes per scanline.
; Each 8-pixel cell occupies one byte. Even/odd cell columns are separated
; into the first/second 8K halves of page 5 and page 1.
; -------------------------------------------------------------------------
RenderGlyph_ATM640112:
        CALL    ATM_CalcPixelOffset112
        LD      A,(Temp_X112)
        AND     1
        LD      (ATM_Parity112),A

        ; Bitmap byte in page 5.
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

        ; Attribute byte in page 1, same parity half.
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

; -------------------------------------------------------------------------
; ATM EGA 320x200x16.
; One character cell is 8 pixels = four two-pixel bytes.
; Each scanline has 160 pair bytes, distributed across four 8K regions.
; CPU address offset within each region is row*40 + cell_column.
;
; Pair order across regions (ATM2+ architecture document, section 5.4):
;   0: page 1, first half ($C000)
;   1: page 5, first half ($4000)
;   2: page 1, second half ($E000)
;   3: page 5, second half ($6000)
; The matching address table is ATM_EGA_PlaneBases112 in main.asm.
; -------------------------------------------------------------------------
RenderGlyph_ATMEGA112:
        CALL    ATM_CalcEGARowOffset112
        ; One character cell contributes one byte to each EGA region.
        ; The per-region column stride is therefore X, not X*4.
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
        ; Extract the next two source pixels, left pixel first.
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

        ; Select one of the four hardware video regions.
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

; -------------------------------------------------------------------------
; ATM 80x25 hardware text.
; Page 5 character codes:
;   even columns -> $01C0 + row*64 + column/2
;   odd columns  -> $21C0 + row*64 + column/2
; Page 1 attributes are crossed:
;   even columns -> $21C0 + row*64 + column/2
;   odd columns  -> $01C0 + row*64 + column/2
; -------------------------------------------------------------------------
RenderChar_ATMText112:
        CALL    ATM_CalcTextOffset112
        LD      A,(Temp_X112)
        AND     1
        LD      (ATM_Parity112),A

        ; Character code in page 5.
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

        ; Attribute byte in page 1, opposite parity half.
        LD      HL,(ATM_Offset112)
        LD      A,(ATM_Parity112)
        OR      A
        JR      Z,ATMTextAttrEven112

        ; MAME ATM2+ video fetch:
        ; odd column: page 1, base $C000, plus BIT(x,3) = +1.
        LD      DE,$C000
        ADD     HL,DE
        INC     HL
        JR      ATMTextAttrStore112

ATMTextAttrEven112:
        ; even column: page 1 second 8K half ($E000).
        LD      DE,$E000
        ADD     HL,DE

ATMTextAttrStore112:
        LD      A,$47
        LD      (HL),A
        RET

; 640x200 offset: (character_row*8 + glyph_line)*40 + column/2.
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

; 80x25 offset: $01C0 + character_row*64 + column/2.
ATM_CalcTextOffset112:
        LD      A,(Temp_Y112)
        LD      L,A
        LD      H,0
        ADD     HL,HL
        ADD     HL,HL
        ADD     HL,HL
        ADD     HL,HL
        ADD     HL,HL
        ADD     HL,HL
        LD      DE,$01C0
        ADD     HL,DE
        LD      A,(Temp_X112)
        SRL     A
        LD      E,A
        LD      D,0
        ADD     HL,DE
        LD      (ATM_Offset112),HL
        RET

; EGA row offset: (character_row*8 + glyph_line)*40.
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

; A*40 = A*5*8. Stores row offset without a column term.
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
