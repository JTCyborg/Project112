; =========================================================================
; PERFECT COMMANDER 112 — ГЕOМЕТРИЯ ПСЕВДOГРAФИКИ СТЕНДA 384x304
; МОДУЛЬ: src/graphics_384.asm (МОНОХРОМНЫЙ ВЫВОД РАМОК)
; =========================================================================

DrawHeader_384x304:
        PUSH    BC
        PUSH    DE
        PUSH    HL
        
        LD      D, 0
.loop_y:
        LD      C, 0
.loop_x:
        PUSH    BC
        PUSH    DE
        LD      A, 32                   ; Символ пробела для чистой заливки
        PUSH    AF
        CALL    PrintChar_384x304
        POP     AF
        POP     DE
        POP     BC
        
        INC     C                       ; Линейный инкремент на 1 байт
        LD      A, C
        CP      48                      ; Ширина экрана — 48 знакомест (байт)
        JR      NZ, .loop_x
        
        INC     D
        LD      A, D
        CP      2                       ; Высота шапки — 2 знакоместа
        JR      NZ, .loop_y

        POP     HL
        POP     DE
        POP     BC
        RET

DrawPanels_384x304:
        PUSH    BC
        PUSH    DE
        PUSH    HL

        ; Отрисовка верхней горизонтальной рамки панелей (строка Y = 2)
        LD      C, 0
.h_loop1:
        PUSH    BC
        PUSH    DE
        LD      D, 2
        LD      A, 45                   ; Код символа '-' в стандартном ASCII
        PUSH    AF
        CALL    PrintChar_384x304
        POP     AF
        POP     DE
        POP     BC
        INC     C
        LD      A, C
        CP      48
        JR      NZ, .h_loop1

        ; Отрисовка нижней горизонтальной границы панелей (строка Y = 35)
        LD      C, 0
.h_loop2:
        PUSH    BC
        PUSH    DE
        LD      D, 35
        LD      A, 45                   
        PUSH    AF
        CALL    PrintChar_384x304
        POP     AF
        POP     DE
        POP     BC
        INC     C
        LD      A, C
        CP      48
        JR      NZ, .h_loop2

        ; Отрисовка центрального вертикального разделителя (Колонка X = 24 байт)
        LD      D, 2
.v_loop:
        PUSH    DE
        PUSH    BC
        LD      C, 24
        LD      A, 124                  ; Код символа '|' в стандартном ASCII
        PUSH    AF
        CALL    PrintChar_384x304
        POP     AF
        POP     BC
        POP     DE
        INC     D
        LD      A, D
        CP      35                      ; Высота панелей — до 35 строки
        JR      NZ, .v_loop

        POP     HL
        POP     DE
        POP     BC
        RET
