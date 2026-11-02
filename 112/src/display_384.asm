; =========================================================================
; PERFECT COMMANDER 112 — СИСТЕМНЫЙ ДРАЙВЕР СТРАНИЧНОЙ ВИДЕOПАМЯТИ
; МОДУЛЬ: src/display_384.asm (КАНОНИЧЕСКАЯ АДРЕСАЦИЯ PENTAGON 384)
; =========================================================================

ClearScreen_384x304:
        PUSH    AF
        PUSH    BC
        PUSH    DE
        PUSH    HL
        
        LD      (Temp_Clear_SP), SP
        LD      SP, $7FFF               ; Защитный перенос стека

        ; 1. Очищаем центральный экран в RAM 5 ($4000..$57FF)
        LD      A, #15                  
        LD      BC, #7FFD
        OUT     (C), A
        LD      HL, $4000
        LD      DE, $4001
        LD      BC, 6143
        LD      (HL), 0                 ; Пиксели в ноль
        LDIR

        ; СБРОС АТРИБУТОВ В RAM 5 ДЛЯ ПРЕДОТВРАЩЕНИЯ ИНВЕРСИИ И БИРЮЗОВОГО ШУМА
        LD      HL, $5800
        LD      DE, $5801
        LD      BC, 767
        LD      (HL), %00000111         ; Черный фон, белый текст (убирает бирюзу)
        LDIR

        ; 2. Очищаем боковые панели в RAM 1 (через те же адреса $4000..$57FF)
        LD      A, #11                  
        LD      BC, #7FFD
        OUT     (C), A
        LD      HL, $4000
        LD      DE, $4001
        LD      BC, 6143
        LD      (HL), 0                 
        LDIR

        LD      HL, $5800
        LD      DE, $5801
        LD      BC, 767
        LD      (HL), %00000111         ; Черный фон, белый текст
        LDIR

        ; Возврат на системную RAM 0
        LD      A, #10
        LD      BC, #7FFD
        OUT     (C), A
        
        LD      SP, (Temp_Clear_SP)
        POP     HL
        POP     DE
        POP     BC
        POP     AF
        RET

PrintString_384x304:
        LD      A, (HL)
        OR      A                       
        RET     Z                       
        PUSH    HL
        PUSH    BC                      ; Защита горизонтального счетчика X
        CALL    PrintChar_384x304
        POP     BC
        
        INC     C                       ; В монохромном режиме 384 шаг равен ровно 1 байту!
        
        POP     HL
        INC     HL
        JR      PrintString_384x304

PrintChar_384x304:
        PUSH    AF
        PUSH    BC
        PUSH    DE
        PUSH    HL

        ; Буферизируем координаты вывода
        LD      A, C
        LD      (Temp_X_Pos), A
        LD      A, D
        LD      (Temp_Y_Pos), A

        ; Извлекаем символ из стека хоста
        PUSH    IX
        LD      IX, 0
        ADD     IX, SP                  
        LD      A, (IX + 14)            ; Коррекция смещения из-за PUSH BC в PrintString
        POP     IX                      

        SUB     32                      ; Коррекция под таблицу шрифта
        LD      L, A
        LD      H, 0
        ADD     HL, HL                  
        ADD     HL, HL                  
        ADD     HL, HL                  
        LD      BC, EXTERNAL_FONT_BIN112 
        ADD     HL, BC                  
        LD      (Temp_Font_Ptr), HL     

        LD      A, 8
        LD      (Char_Height_Counter), A

.line_render_loop:
        LD      A, 8
        LD      HL, Char_Height_Counter
        SUB     (HL)
        LD      (Current_Pixel_Line), A 

        ; --- КАНОНИЧЕСКИЙ РАСЧЕТ АДРЕСА СТРОКИ ALONE CODER ---
        LD      A, (Temp_Y_Pos)
        LD      B, A                    
        
        LD      A, B
        AND     %00011000               
        RRA
        RRA
        RRA
        OR      %01000000               ; Базовый экранный сегмент $4000
        LD      H, A
        LD      A, (Current_Pixel_Line)
        OR      H
        LD      H, A                    

        LD      A, B
        AND     %00000111               
        RLC     A
        RLC     A
        RLC     A
        RLC     A
        RLC     A                       
        LD      L, A                    

        ; Читаем байт маски шрифта
        PUSH    HL
        LD      HL, (Temp_Font_Ptr)
        LD      A, (HL)
        INC     HL
        LD      (Temp_Font_Ptr), HL
        LD      (Temp_Pixel_Byte), A    
        POP     HL

        ; Горизонтальное распределение X по банкам памяти Pentagon 384
        LD      A, (Temp_X_Pos)
        CP      8
        JR      C, .in_side_lanes       ; X < 8  -> Левый бордюр (физически в RAM 1)
        CP      40
        JR      NC, .in_side_lanes      ; X >= 40 -> Правый бордюр (физически в RAM 1)

        ; Центральная область экрана (Стандартная RAM 5, адреса $4000..$57FF)
        SUB     8                       
        ADD     A, L
        LD      L, A
        
        ; Переключаемся на RAM 5 для гарантированной чистой записи символов центрального экрана
        LD      B, A
        LD      A, #15
        LD      BC, #7FFD
        OUT     (C), A
        LD      A, (Temp_Pixel_Byte)
        LD      (HL), A                 
        LD      A, #10
        OUT     (C), A
        JR      .line_done

.in_side_lanes:
        ; Боковые панели маппятся в RAM 1 на те же адреса развертки
        CP      40
        JR      C, .left_lane
        SUB     40
        ADD     A, 32                   ; Смещение правого бордюра в структуре строки
        JR      .apply_side
.left_lane:
        ; Левый бордюр (0..7)
.apply_side:
        ADD     A, L
        LD      L, A

        ; Безопасный атомарный вывод в альтернативную банку ОЗУ
        LD      A, (Temp_Pixel_Byte)
        CALL    Write_SideLane_Atomic

.line_done:
        LD      HL, Char_Height_Counter
        DEC     (HL)
        JP      NZ, .line_render_loop

        POP     HL
        POP     DE
        POP     BC
        POP     AF
        RET

; --- АТОМАРНЫЙ ВЫВОД В БОКОВЫЕ ПАНЕЛИ (RAM 1) ---
Write_SideLane_Atomic:
        PUSH    BC
        PUSH    AF
        
        LD      A, #11                  ; Включаем RAM 1 (Боковой экран)
        LD      BC, #7FFD
        OUT     (C), A
        
        POP     AF
        LD      (HL), A                 
        
        LD      A, #10                  ; Возвращаем стабильное ядро RAM 0
        LD      BC, #7FFD
        OUT     (C), A
        
        POP     BC
        RET
