; =========================================================================
; PROJECT112 — INDEPENDENT AlCo 384x304 DRIVER
; Target: Pentagon 1024 / AlCo 384x304 memory layout
;
; Public entry points:
;   Alco384_Init       Select RAM page 4 at $C000; page 5 is at $4000.
;   Alco384_Clear      Clear both 16K physical screen pages.
;   Alco384_WriteByte  BC=scanline (0..303), E=byte column (0..47), A=value.
;   Alco384_SetPixel   BC=Y (0..303), DE=X (0..383), A=0 clear / nonzero set.
;   Alco384_SetAttr    BC=attribute scanline (0..303), E=byte column, A=value.
;
; Registers:
;   All public routines preserve BC, DE and HL.
;   AF is preserved by Init/Clear; WriteByte/SetPixel/SetAttr consume A.
;   SetPixel does nothing for coordinates outside 384x304.
;
; No standard character renderer or mode dispatcher is called.
; Address equations are the AlCo XYSC384/YSC384/SA384 equations.
; =========================================================================

Alco384_Init:
        PUSH    AF
        PUSH    BC
        LD      A,$04
        LD      BC,$7FFD
        OUT     (C),A
        POP     BC
        POP     AF
        RET

; Clear page 5 at $4000 and page 4 at $C000.
Alco384_Clear:
        PUSH    AF
        PUSH    BC
        PUSH    DE
        PUSH    HL
        CALL    Alco384_Init

        LD      HL,$4000
        LD      DE,$4001
        LD      BC,$3FFF
        XOR     A
        LD      (HL),A
        LDIR

        LD      HL,$C000
        LD      DE,$C001
        LD      BC,$3FFF
        LD      (HL),A
        LDIR

        POP     HL
        POP     DE
        POP     BC
        POP     AF
        RET

; BC=scanline 0..303, E=byte column 0..47, A=byte value.
Alco384_WriteByte:
        PUSH    AF
        PUSH    BC
        PUSH    DE
        CALL    Alco384_XYSC
        POP     DE
        POP     BC
        POP     AF
        LD      (HL),A
        RET

; BC=Y 0..303, DE=X 0..383, A=0 clears / nonzero sets the pixel.
Alco384_SetPixel:
        PUSH    AF
        PUSH    BC
        PUSH    DE
        PUSH    HL

        LD      (Alco384_PixelValue),A

        ; Validate Y: only 0..303 is legal.
        LD      A,B
        CP      2
        JR      NC,Alco384_PixelExit
        OR      A
        JR      NZ,Alco384_CheckYHigh
        JR      Alco384_CheckX
Alco384_CheckYHigh:
        LD      A,C
        CP      48
        JR      NC,Alco384_PixelExit

Alco384_CheckX:
        ; Validate X: only 0..383 is legal.
        LD      A,D
        CP      2
        JR      NC,Alco384_PixelExit
        OR      A
        JR      NZ,Alco384_CheckXHigh
        JR      Alco384_PixelCoordinatesOK
Alco384_CheckXHigh:
        LD      A,E
        CP      128
        JR      NC,Alco384_PixelExit

Alco384_PixelCoordinatesOK:
        ; Save Y and derive bit mask from X modulo 8.
        LD      A,B
        LD      (Alco384_PixelYHigh),A
        LD      A,C
        LD      (Alco384_PixelYLow),A

        LD      A,E
        AND     7
        LD      B,A
        LD      A,$80
Alco384_MakeMask:
        LD      A,B
        OR      A
        JR      Z,Alco384_MaskReady
        LD      A,$80
Alco384_MaskLoop:
        RRCA
        DJNZ    Alco384_MaskLoop
Alco384_MaskReady:
        LD      (Alco384_PixelMask),A

        ; Divide the 16-bit X coordinate by eight to get byte column.
        LD      A,D
        LD      D,A
        LD      A,E
        LD      E,A
        SRL     D
        RR      E
        SRL     D
        RR      E
        SRL     D
        RR      E

        LD      A,(Alco384_PixelYHigh)
        LD      B,A
        LD      A,(Alco384_PixelYLow)
        LD      C,A
        CALL    Alco384_XYSC

        LD      A,(Alco384_PixelValue)
        OR      A
        JR      Z,Alco384_ClearPixelBit
        LD      A,(HL)
        LD      B,A
        LD      A,(Alco384_PixelMask)
        OR      B
        LD      (HL),A
        JR      Alco384_PixelExit

Alco384_ClearPixelBit:
        LD      A,(Alco384_PixelMask)
        CPL
        LD      B,A
        LD      A,(HL)
        AND     B
        LD      (HL),A

Alco384_PixelExit:
        POP     HL
        POP     DE
        POP     BC
        POP     AF
        RET

; BC=scanline (normally character-row*8), E=byte column 0..47, A=attribute.
Alco384_SetAttr:
        PUSH    AF
        PUSH    BC
        PUSH    DE
        CALL    Alco384_XYSC
        CALL    Alco384_SA
        POP     DE
        POP     BC
        POP     AF
        LD      (HL),A
        RET

; -------------------------------------------------------------------------
; AlCo address conversion.
; Input XYSC: BC=scanline, E=byte column.
; Output: HL=bitmap address in currently mapped page 4/page 5.
; -------------------------------------------------------------------------
Alco384_XYSC:
        CALL    Alco384_YSC
        LD      A,E
        SUB     8
        JR      C,Alco384_XLeft
        CP      32
        JR      C,Alco384_XMiddle
        SUB     32+$18
Alco384_XLeft:
        ADD     A,8+$18
        JR      Alco384_XAdd
Alco384_XMiddle:
        SET     5,H
Alco384_XAdd:
        ADD     A,L
        LD      L,A
        RET

Alco384_YSC:
        LD      A,C
        AND     7
        LD      H,A
        XOR     C
        ADD     A,A
        ADD     A,A
        LD      L,A
        LD      A,$D8
        INC     B
        DJNZ    Alco384_YLow
        LD      A,C
        AND     $C0
        RRCA
        RRCA
        RRCA
        JR      NZ,Alco384_YSkipLoad
        LD      A,$C0-$38
Alco384_YSkipLoad:
        ADD     A,$38
        ADD     A,H
        LD      H,A
        RET
Alco384_YLow:
        ADD     A,H
        LD      H,A
        RET

; Convert bitmap address HL to the corresponding AlCo attribute address.
Alco384_SA:
        LD      A,H
        AND     $D8
        JP      P,Alco384_SAPositive
        ADD     A,$86-$C0-$C2+$40
Alco384_SAPositive:
        ADD     A,$C2-$40
        RRCA
        RRCA
        RRCA
        XOR     H
        AND     $DF
        XOR     H
        LD      H,A
        RET

Alco384_PixelValue:  DB 0
Alco384_PixelMask:   DB 0
Alco384_PixelYLow:   DB 0
Alco384_PixelYHigh:  DB 0
