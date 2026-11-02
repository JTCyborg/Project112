; =========================================================================
; PROJECT112 — VIDEO MODE 4: PENTAGON 384x304
; RAM page 4 is mapped at $C000; RAM page 5 is fixed at $4000.
; XYSC384 selects the appropriate window for each vertical screen band.
; =========================================================================

ClearVideoMemory_384112:
        ; Clear the fixed RAM page 5 window ($4000-$7FFF).
        LD      A,$10
        LD      BC,$7FFD
        OUT     (C),A
        LD      HL,$4000
        LD      DE,$4001
        LD      BC,$3FFF
        LD      (HL),0
        LDIR

        ; Map RAM page 4 at $C000 and clear it. XYSC384 uses this page
        ; for the top and bottom bands of the 384x304 screen.
        LD      A,$04
        LD      BC,$7FFD
        OUT     (C),A
        LD      HL,$C000
        LD      DE,$C001
        LD      BC,$3FFF
        LD      (HL),0
        LDIR
        RET

RenderGlyph_384112:
        LD      A,(Temp_Y112)
        LD      C,A
        LD      B,0
        SLA     C
        RL      B
        SLA     C
        RL      B
        SLA     C
        RL      B
        LD      A,(GlyphLine112)
        ADD     A,C
        LD      C,A
        JR      NC,.y_ok
        INC     B
.y_ok:
        LD      A,(Temp_X112)
        LD      E,A
        CALL    XYSC384_112
        LD      A,(Temp_FontByte112)
        LD      (HL),A
        RET

RenderAttributes_384112:
        LD      A,(Temp_Y112)
        LD      C,A
        LD      B,0
        SLA     C
        RL      B
        SLA     C
        RL      B
        SLA     C
        RL      B
        LD      A,(Temp_X112)
        LD      E,A
        CALL    XYSC384_112
        CALL    SA384_112
        LD      A,$07
        LD      (HL),A
        RET

; XYSC384 input: BC=scanline 0..303, E=byte column 0..47.
; Output: HL=bitmap address in the appropriate mapped RAM window.
XYSC384_112:
        CALL    YSC384_112
        LD      A,E
        SUB     8
        JR      C,XS384Left112
        CP      32
        JR      C,XS384Middle112
        SUB     32+$18
XS384Left112:
        ADD     A,8+$18
        JR      XS384Add112
XS384Middle112:
        SET     5,H
XS384Add112:
        ADD     A,L
        LD      L,A
        RET

YSC384_112:
        LD      A,C
        AND     7
        LD      H,A
        XOR     C
        ADD     A,A
        ADD     A,A
        ADD     A,A
        ADD     A,A
        LD      L,A
        LD      A,$D8
        INC     B
        DJNZ    YSC384Low112
        LD      A,C
        AND     $C0
        RRCA
        RRCA
        RRCA
        JR      NZ,YSC384SkipLoad112
        LD      A,$C0-$38
YSC384SkipLoad112:
        ADD     A,$38
        ADD     A,H
        LD      H,A
        RET
YSC384Low112:
        ADD     A,H
        LD      H,A
        RET

SA384_112:
        LD      A,H
        AND     $D8
        JP      P,SA384Positive112
        ADD     A,$86-$C0-$C2+$40
SA384Positive112:
        ADD     A,$C2-$40
        RRCA
        RRCA
        RRCA
        XOR     H
        AND     $DF
        XOR     H
        LD      H,A
        RET
