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
        ; YSC384 uses (Y & $F8) * 4, not *16.
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

; 384x304 bitmap geometry test: nested byte-aligned outlines.
; Insets: 0,16,32,48,64,80 pixels. Bitmap only; attributes bypassed.
Draw384RectangleTest112:
        LD      A,$04
        LD      BC,$7FFD
        OUT     (C),A
        LD      A,0
        LD      (RectLeftByte112),A
        LD      A,47
        LD      (RectRightByte112),A
        LD      A,0
        LD      (RectTopLo112),A
        LD      (RectTopHi112),A
        LD      A,47
        LD      (RectBottomLo112),A
        LD      A,1
        LD      (RectBottomHi112),A
        CALL    Draw384OneRectangle112
        LD      A,2
        LD      (RectLeftByte112),A
        LD      A,45
        LD      (RectRightByte112),A
        LD      A,16
        LD      (RectTopLo112),A
        XOR     A
        LD      (RectTopHi112),A
        LD      A,31
        LD      (RectBottomLo112),A
        LD      A,1
        LD      (RectBottomHi112),A
        CALL    Draw384OneRectangle112
        LD      A,4
        LD      (RectLeftByte112),A
        LD      A,43
        LD      (RectRightByte112),A
        LD      A,32
        LD      (RectTopLo112),A
        XOR     A
        LD      (RectTopHi112),A
        LD      A,15
        LD      (RectBottomLo112),A
        LD      A,1
        LD      (RectBottomHi112),A
        CALL    Draw384OneRectangle112
        LD      A,6
        LD      (RectLeftByte112),A
        LD      A,41
        LD      (RectRightByte112),A
        LD      A,48
        LD      (RectTopLo112),A
        XOR     A
        LD      (RectTopHi112),A
        LD      A,255
        LD      (RectBottomLo112),A
        XOR     A
        LD      (RectBottomHi112),A
        CALL    Draw384OneRectangle112
        LD      A,8
        LD      (RectLeftByte112),A
        LD      A,39
        LD      (RectRightByte112),A
        LD      A,64
        LD      (RectTopLo112),A
        XOR     A
        LD      (RectTopHi112),A
        LD      A,239
        LD      (RectBottomLo112),A
        XOR     A
        LD      (RectBottomHi112),A
        CALL    Draw384OneRectangle112
        LD      A,10
        LD      (RectLeftByte112),A
        LD      A,37
        LD      (RectRightByte112),A
        LD      A,80
        LD      (RectTopLo112),A
        XOR     A
        LD      (RectTopHi112),A
        LD      A,223
        LD      (RectBottomLo112),A
        XOR     A
        LD      (RectBottomHi112),A
        CALL    Draw384OneRectangle112
        ; Central vertical reference line.
        LD      A,23
        LD      (RectLeftByte112),A
        LD      (RectRightByte112),A
        XOR     A
        LD      (RectTopLo112),A
        LD      (RectTopHi112),A
        LD      A,47
        LD      (RectBottomLo112),A
        LD      A,1
        LD      (RectBottomHi112),A
        CALL    Draw384OneRectangle112
        RET

Draw384OneRectangle112:
        LD      A,(RectTopLo112)
        LD      (RectYLo112),A
        LD      A,(RectTopHi112)
        LD      (RectYHi112),A
Draw384VerticalLoop112:
        LD      A,(RectYLo112)
        LD      C,A
        LD      A,(RectYHi112)
        LD      B,A
        LD      A,(RectLeftByte112)
        LD      E,A
        PUSH    BC
        CALL    XYSC384_112
        LD      A,$FF
        LD      (HL),A
        POP     BC
        LD      A,(RectYLo112)
        LD      C,A
        LD      A,(RectYHi112)
        LD      B,A
        LD      A,(RectRightByte112)
        LD      E,A
        PUSH    BC
        CALL    XYSC384_112
        LD      A,$FF
        LD      (HL),A
        POP     BC
        LD      A,(RectYLo112)
        LD      C,A
        LD      A,(RectYHi112)
        LD      B,A
        LD      A,(RectTopLo112)
        CP      C
        JR      NZ,Draw384CheckBottom112
        LD      A,(RectTopHi112)
        CP      B
        CALL    Z,Draw384Horizontal112
        JR      Draw384AdvanceY112
Draw384CheckBottom112:
        LD      A,(RectBottomLo112)
        CP      C
        JR      NZ,Draw384AdvanceY112
        LD      A,(RectBottomHi112)
        CP      B
        CALL    Z,Draw384Horizontal112
Draw384AdvanceY112:
        LD      A,(RectYLo112)
        LD      C,A
        LD      A,(RectYHi112)
        LD      B,A
        LD      A,(RectBottomLo112)
        CP      C
        JR      NZ,Draw384IncrementY112
        LD      A,(RectBottomHi112)
        CP      B
        RET     Z
Draw384IncrementY112:
        LD      A,(RectYLo112)
        INC     A
        LD      (RectYLo112),A
        JR      NZ,Draw384VerticalLoop112
        LD      A,(RectYHi112)
        INC     A
        LD      (RectYHi112),A
        JR      Draw384VerticalLoop112

Draw384Horizontal112:
        LD      A,(RectLeftByte112)
        LD      (RectXByte112),A
Draw384HorizontalLoop112:
        LD      A,(RectYLo112)
        LD      C,A
        LD      A,(RectYHi112)
        LD      B,A
        LD      A,(RectXByte112)
        LD      E,A
        PUSH    BC
        CALL    XYSC384_112
        LD      A,$FF
        LD      (HL),A
        POP     BC
        LD      A,(RectXByte112)
        INC     A
        LD      (RectXByte112),A
        LD      B,A
        LD      A,(RectRightByte112)
        CP      B
        JR      NC,Draw384HorizontalLoop112
        RET
