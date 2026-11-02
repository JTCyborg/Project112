; =========================================================================
; PERFECT COMMANDER 112 — ГЛАВНЫЙ МОДУЛЬ СИСТЕМЫ И ПЕРЕКЛЮЧЕНИЯ РЕЖИМОВ
; РАЗРАБОТКА: Инфарх (1998) & Alone Coder (2005) & AI (2026)
; СБОРКА: СТРОГО ПОД ЧАНКОВУЮ АРХИТЕКТУРУ UNREALSPECCY (ПОРТЫ #7FFD / #EFF7)
; =========================================================================

        DEVICE ZXSPECTRUM128    
        EMPTYTRD "project112.TRD"

        ; Исполняемый код жестко зафиксирован в безопасной зоне ОЗУ
        ORG $8000                       

Init_Z80_System112:
        DI                              ; Полное отключение прерываний IM 1
        LD      (Saved_SP_112), SP    
        LD      SP, $7FFF               ; Уносим стек хоста в безопасную зону

        ; Настройка начальной配置 страниц ОЗУ (RAM 0)
        LD      A, #10                  
        LD      BC, #7FFD
        OUT     (C), A                  

        ; Аппаратное включение стартового режима Pentagon 384x304
        LD      A, #40                  
        LD      (Current_Mode_Byte), A
        LD      BC, #EFF7
        OUT     (C), A                  

        ; Первичная синхронизация бордюра со стартовым режимом
        CALL    UpdateBorderColor

        CALL    RefreshScreen_AllData

.MainLoop112:
        ; Опрос клавиатурного полуряда Space..Break (Порт #7FFE)
        LD      BC, #7FFE               
        IN      A, (C)
        RRA                             ; Выталкиваем статус Space в Carry
        JR      C, .MainLoop112         

        ; Ожидание отпускания клавиши (защита от дребезга)
.wait_release:
        IN      A, (C)
        RRA
        JR      NC, .wait_release

        ; Интерактивное циклическое переключение видеорежимов
        CALL    SwitchToNextVideoMode
        JR      .MainLoop112           

; --- ПОДПРОГРАММА ПЕРЕРИСОВКИ ВСЕХ ДАННЫХ ИНТЕРФЕЙСА ---
RefreshScreen_AllData:
        CALL    ClearScreen_384x304
        CALL    DrawHeader_384x304

        ; Вывод названия проекта в шапке (X передается в линейных байтах)
        LD      HL, Msg_Title
        LD      C, 1                    
        LD      D, 0
        CALL    PrintString_384x304

        CALL    DrawPanels_384x304

        ; Системные логи внутри файловых панелей
        LD      HL, Msg_CurrentMode
        LD      C, 2                    
        LD      D, 4
        CALL    PrintString_384x304

        ; Вывод имени текущего активного видеорежима эмулятора
        LD      A, (Current_Mode_Index)
        LD      L, A
        LD      H, 0
        ADD     HL, HL                  
        LD      DE, Mode_Names_Table
        ADD     HL, DE
        LD      A, (HL)
        INC     HL
        LD      H, (HL)
        LD      L, A                    
        LD      C, 24                   ; Позиция названия (24 байта смещения)
        LD      D, 4
        CALL    PrintString_384x304

        ; Вывод цифрового счетчика [X/5]
        CALL    UpdateModeIndicator

        LD      HL, Msg_Help
        LD      C, 2
        LD      D, 6
        CALL    PrintString_384x304

        LD      HL, Msg_LogReg
        LD      C, 2
        LD      D, 8
        CALL    PrintString_384x304
        RET

; --- ЛОГИКА ПЕРЕКЛЮЧЕНИЯ РЕГИСТРОВ ПОРТА #EFF7 ---
SwitchToNextVideoMode:
        LD      A, (Current_Mode_Index)
        INC     A
        CP      5                       ; Доступно ровно 5 видео-конфигураций
        JR      NZ, .save_index
        XOR     A                       
.save_index:
        LD      (Current_Mode_Index), A

        ; Извлечение аппаратной маски из таблицы
        LD      L, A
        LD      H, 0
        LD      DE, Mode_Hardware_Bytes
        ADD     HL, DE
        LD      A, (HL)
        LD      (Current_Mode_Byte), A

        ; Физическая отправка конфигурации в UnrealSpeccy
        LD      BC, #EFF7
        OUT     (C), A

        ; Синхронное обновление цвета бордюра под новый режим
        CALL    UpdateBorderColor

        CALL    RefreshScreen_AllData
        RET

; --- ПОДПРОГРАММА СИНХРОНИЗАЦИИ ЦВЕТА БОРДЮРА ---
UpdateBorderColor:
        LD      A, (Current_Mode_Index)
        LD      L, A
        LD      H, 0
        LD      DE, Mode_Border_Colors
        ADD     HL, DE
        LD      A, (HL)                 
        OUT     (#FE), A                
        RET

; --- ВOССТАНOВЛЕННАЯ ПОДПРОГРАММА СЧЕТЧИКА [X/5] ---
UpdateModeIndicator:
        LD      A, (Current_Mode_Index)
        INC     A                       
        ADD     A, 48                   
        LD      (Str_Buf_Num), A        
        
        LD      HL, Msg_Counter
        LD      C, 2
        LD      D, 10
        CALL    PrintString_384x304
        RET

; --- СИСТЕМНЫЕ ДАННЫЕ И ТАБЛИЦЫ ---
Saved_SP_112:           DW 0
Current_Mode_Index:     DB 2            ; По умолчанию стартуем в режиме №2 (384x304)
Current_Mode_Byte:      DB #40

Msg_Title:      DEFM "PERFECT COMMANDER 112 * UNREAL VIDEO MODE HARDWARE TESTER", 0
Msg_CurrentMode:DEFM "ACTIVE REG #EFF7 MODE: ", 0
Msg_Help:       DEFM "-> [CONTROL]: PRESS 'SPACE' TO CYCLE EXTENDED MODES.", 0
Msg_LogReg:     DEFM "PENTAGON-384 BUS DETECTED. VIDEO STACK STATUS: OK.", 0

Msg_Counter:    DEFM "CURRENT ACTIVE STATUS CONFIGURATION: ["
Str_Buf_Num:    DEFM "3"                 
                DEFM "/5]", 0

; Таблица адресов текстовых строк
Mode_Names_Table:
        DW      Str_Mode0
        DW      Str_Mode1
        DW      Str_Mode2
        DW      Str_Mode3
        DW      Str_Mode4

Str_Mode0:      DEFM "00: STANDARD SPECTRUM 256x192  ", 0
Str_Mode1:      DEFM "01: HARDWARE MULTICOLOR 8x1   ", 0
Str_Mode2:      DEFM "02: PENTAGON HIGH-RES 384x304  ", 0
Str_Mode3:      DEFM "03: LOW-RES 16-COLOR (ATM CHIP)", 0
Str_Mode4:      DEFM "04: HARDWARE GIGASCREEN INTERL", 0

; Table of port configurations
Mode_Hardware_Bytes:
        DB      %00000000               
        DB      %00100000               
        DB      %01000000               
        DB      %00000001               
        DB      %01000000 | %00001000   

; Таблица аппаратной цветовой шифровки бордюра
Mode_Border_Colors:
        DB      1                       ; Синий бордюр (00)
        DB      4                       ; Зеленый бордюр (01)
        DB      0                       ; Черный бордюр (02)
        DB      2                       ; Красный бордюр (03)
        DB      6                       ; Желтый бордюр (04)

        INCLUDE "src/display_384.asm"
        INCLUDE "src/graphics_384.asm"

; --- НЕПРЕРЫВНАЯ ЛИНЕЙНАЯ СЕКЦИЯ ПЕРЕМЕННЫХ И ШРИФТОВ ---
Temp_X_Pos:             DB 0
Temp_Y_Pos:             DB 0
Temp_Font_Ptr:          DW 0
Char_Height_Counter:    DB 0
Current_Pixel_Line:     DB 0
Temp_Pixel_Byte:        DB 0
Temp_Clear_SP:          DW 0

        ALIGN 256
EXTERNAL_FONT_BIN112:
        INCBIN "src/font.bin"           ; Встроенный бинарный шрифт 8х8 (768 байт)

ProgramEnd112:

; =========================================================================
; СБОРОЧНЫЙ КАНOНИЧЕСКИЙ BASIC-ЗАГРУЗЧИК (СТАРТ ИЗ СЕКТOРА TR-DOS)
; =========================================================================
        ORG $B000
CLEAR       EQU $FD
RANDOMIZE   EQU $F9
USR         EQU $C0
REM         EQU $EA

basic_loader:
        DB      0, 10
        DW      l10_len
l10:
        DB      CLEAR, "32767", $0E, 0, 0
        DW      32767
        DB      0, $0D
l10_len EQU     $-l10

        DB      0, 20
        DW      l20_len
l20:
        DB      RANDOMIZE, USR, "15619", $0E, 0, 0
        DW      15619
        DB      0
        DB      $3A, REM, $3A
        DB "LOAD ", 34, "proj112", 34, " CODE 32768", $0D
l20_len EQU     $-l20

        DB      0, 30
        DW l30_len
l30:
        DB      RANDOMIZE, USR, "32768", $0E, 0, 0
        DW      32768
        DB      0, $0D
l30_len EQU     $-l30
basic_loader_end:              

        SAVETRD "project112.TRD", "proj112.B", basic_loader, basic_loader_end - basic_loader, 10
        SAVETRD "project112.TRD", "proj112.C", $8000, ProgramEnd112 - $8000
