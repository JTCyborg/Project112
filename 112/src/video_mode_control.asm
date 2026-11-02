; =========================================================================
; PROJECT112 — VIDEO MODE CONTROL PIPELINE (UNREAL_SPECCY SYNCED)
; Cyclic mode selection, hardware register and paging setup.
; =========================================================================

SwitchToNextVideoMode:
        LD      A,(Current_Mode_Index)
        INC     A
        CP      Mode_Count
        JR      C,ModeIndexReady112
        XOR     A
ModeIndexReady112:
        LD      (Current_Mode_Index),A
        CALL    ApplyVideoMode
        CALL    DrawDemoScreen
        RET

ApplyVideoMode:
        LD      HL,Debug_ModeApply112
        CALL    DebugPrintString112
        
        ; 1. Настройка и коммутация конфигурационного порта $EFF7
        LD      A,(Current_Mode_Index)
        LD      L,A
        LD      H,0
        LD      DE,Mode_Hardware_Bytes
        ADD     HL,DE
        LD      A,(HL)
        LD      (Current_Mode_Byte),A
        LD      BC,$EFF7
        OUT     (C),A

        ; 2. Распределение системных страниц памяти через порт $7FFD
        LD      A,(Current_Mode_Index)
        CP      3                       ; Режим 3: 16-Color
        JR      Z,.init_16color_pages
        CP      4                       ; Режим 4: Pentagon 384x304
        JR      Z,.init_384_pages

        ; Стандартная конфигурация для режимов 0, 1, 2 (RAM 5)
        LD      A,$10
        JR      ModePageReady112

.init_16color_pages:
        ; Для 16-цветового режима временно даём доступ к RAM 7 ($17), 
        ; чтобы ClearVideoMemory зачистил верхние аппаратные плоскости
        LD      A,$17
        JR      ModePageReady112

.init_384_pages:
        ; ИСПРАВЛЕНИЕ БАГА: Для Pentagon 384 вместо RAM 4 ($04) 
        ; жестко включаем RAM 5 ($15) — именно её ожидает draw_384.cpp в UnrealSpeccy!
        LD      A,$15

ModePageReady112:
        LD      BC,$7FFD
        OUT     (C),A

        ; 3. Установка цвета бордюра через порт $FE
        LD      A,(Current_Mode_Index)
        LD      L,A
        LD      H,0
        LD      DE,Mode_Border_Colors
        ADD     HL,DE
        LD      A,(HL)
        OUT     ($FE),A
        RET


; Mode-control constants and lookup tables.
Mode_Count             EQU 5
Current_Mode_Byte:     DB 0
Debug_ModeApply112:    DEFM "VIDEO MODE APPLY",13,10,0

; UnrealSpeccy / Pentagon 1024 mode bits:
; D0=16-color, D1=512x192, D5=hardware multicolor, D6=384x304.
Mode_Hardware_Bytes:
        DB      $00                     ; Mode 0: Standard 256x192
        DB      $02                     ; Mode 1: 512x192
        DB      $20                     ; Mode 2: Hardware Multicolor
        DB      $01                     ; Mode 3: Pentagon 16-Color
        DB      $40                     ; Mode 4: Pentagon 384x304

Mode_Border_Colors:
        DB      1,2,4,5,6
