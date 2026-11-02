; =========================================================================
; PROJECT112 — VIDEO MODE 3: PENTAGON 16-COLOR (БЕЗОПАСНЫЙ СИНХРОННЫЙ)
; =========================================================================

ClearVideoMemory_16Color112:
        LD      HL,$4000
        LD      DE,$4001
        LD      BC,$3FFF
        LD      (HL),0
        LDIR
        RET

RenderGlyph_16Color112:
        ; 1. Безопасный расчет абсолютного Y строки (0..191)
        LD      A,(Temp_Y112)           ; Y знакоместа (0..23)
        SLA     A
        SLA     A
        SLA     A                       ; A = Y * 8
        LD      B,A
        LD      A,(GlyphLine112)        ; Текущая строка глифа (0..7)
        ADD     A,B                     ; A = Absolute Y (0..191)
        
        ; 2. Вычисляем смещение строки: HL = Y * 32
        LD      L,A
        LD      H,0                     ; HL = Y
        LD      E,L
        LD      D,H                     ; DE = Y
        
        ; Умножаем HL на 32 через 16-битные безопасные сложения
        ADD     HL,HL                   ; *2
        ADD     HL,HL                   ; *4
        ADD     HL,HL                   ; *8
        ADD     HL,HL                   ; *16
        ADD     HL,HL                   ; *32
        
        ; 3. Добавляем горизонтальное смещение X знакоместа
        LD      A,(Temp_X112)
        LD      E,A
        LD      D,0
        ADD     HL,DE                   ; HL = (Y * 32) + X
        
        ; 4. Добавляем базовый адрес видеоокна Пентагона ($4000)
        LD      DE,$4000
        ADD     HL,DE
        LD      (ColorOffset112),HL
        
        ; 5. Инициализация маски шрифта
        LD      A,(Temp_FontByte112)
        LD      (ColorShiftByte112),A
        XOR     A
        LD      (ColorPlaneIndex112),A

.plane_loop:
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
        JP      NZ,.plane_loop
        RET

RenderAttributes_16Color112:
        RET
