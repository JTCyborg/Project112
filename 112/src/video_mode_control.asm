<<<<<<< HEAD
; =========================================================================
; PROJECT112 — VIDEO MODE CONTROL (Аппаратный фикс через ПЗУ TR-DOS)
; =========================================================================
SwitchToNextVideoMode:
        LD      A,(Current_Mode_Index)
        INC     A
        CP      4
        JR      C,ModeIndexReady112
        XOR     A
ModeIndexReady112:
        LD      (Current_Mode_Index),A
        OR      A
        JR      Z,RestoreSinclairMemoryMap112

        ; -----------------------------------------------------------------
        ; ШАГ 1: Активируем DOSEN и сбрасываем бит A9 (CPM=0).
        ; Делаем это через официальную точку ПЗУ TR-DOS #3D2F.
        ; -----------------------------------------------------------------
        LD      BC,ShadowPortsOpened112 ; Адрес возврата в ОЗУ после ПЗУ
        PUSH    BC
        
        LD      BC,#2A53                ; Адрес команды OUT (C),A внутри ПЗУ TR-DOS
        PUSH    BC                      ; Толкаем на стек для выполнения RET из ПЗУ
        
        ; Формируем адрес порта: A9=0 (открыть порты), A14=0 (доступ к палитре)
        LD      BC,#0177                
        LD      A,$C3                   ; Временно удерживаем режим Sinclair (RG=3)
        JP      #3D2F                   ; Прыгаем в ПЗУ. Оно выполнит OUT и вернется к нам

ShadowPortsOpened112:
        ; Теневые порты успешно разблокированы! Теперь диспетчер памяти доступен напрямую.

        ; -----------------------------------------------------------------
        ; ШАГ 2: Маппим страницы видеопамяти ATM в Окна 1 и 3
        ; -----------------------------------------------------------------
        LD      A,$7A                   ; Инверсный номер страницы ОЗУ 5
        LD      BC,$7FF7
        OUT     (C),A                   ; Подключаем в окно $4000-$7FFF
        
        LD      A,$7E                   ; Инверсный номер страницы ОЗУ 1
        LD      BC,$FFF7
        OUT     (C),A                   ; Подключаем в окно $C000-$FFFF
        JR      PrepareVideoRegister112

RestoreSinclairMemoryMap112:
        ; Возвращаем стандартную карту памяти ZX-128
        LD      A,$7F                   ; Инверсная страница ОЗУ 0
        LD      BC,$FFF7
        OUT     (C),A
        XOR     A
        LD      BC,$7FFD
        OUT     (C),A

        ; Закрываем теневые порты обратно, устанавливая бит A9=1 (CPM=1)
        LD      A,$C3                   ; Режим Sinclair (RG=3)
        LD      BC,#FF77                
        OUT     (C),A
        JR      VideoModePostSwitch112

PrepareVideoRegister112:
        ; Извлекаем значение регистра из таблицы
        LD      A,(Current_Mode_Index)
        ADD     A,A
        LD      E,A
        LD      D,0
        LD      HL,VideoModeRegisterTable112
        ADD     HL,DE
        LD      A,(HL)
        OR      $C0                     ; Маскируем обязательные биты VE1=1, VE0=1

        ; -----------------------------------------------------------------
        ; ШАГ 3: Стабилизация через Окно 3 (Адрес $FFEC)
        ; Собираем код на стеке промаппленной и стабильной страницы 1
        ; -----------------------------------------------------------------
        LD      (Safe_Reg_A_112),A      ; Сохраняем А

        LD      HL,$FFEC                ; Пишем опкоды в самый верх памяти
        
        LD      (HL),$01                ; Опкод: LD BC, $FF77
        INC     HL
        LD      (HL),$77
        INC     HL
        LD      (HL),$FF
        INC     HL
        
        LD      (HL),$ED                ; Опкод: OUT (C), A
        INC     HL
        LD      (HL),$79
        INC     HL
        
        LD      (HL),$C3                ; Опкод: JP VideoModePostSwitch112
        INC     HL
        LD      (HL),VideoModePostSwitch112 & $FF
        INC     HL
        LD      (HL),(VideoModePostSwitch112 >> 8) & $FF

        LD      A,(Safe_Reg_A_112)
        JP      $FFEC                   ; Безопасный прыжок в Окно 3 на переключение шины!

; Сюда управление вернется без единого сбоя адресных линий
VideoModePostSwitch112:
        LD      HL,Debug_ModeApplied112
        CALL    DebugPrintString112
        CALL    DrawDemoScreen
        JP      MainLoop112

Safe_Reg_A_112:        DB 0

; -------------------------------------------------------------------------
; Геометрия демонстрационных экранов
; -------------------------------------------------------------------------
DrawDemoScreen:
        CALL    ClearVideoMemory112
        LD      A,(Current_Mode_Index)
        CP      3
        JR      Z,DrawDemoCharacterGrid112

DrawDemoCharacterGrid112:
        LD      A,(Current_Mode_Index)
        OR      A
        JR      Z,GridGeometrySinclair112
        CP      2
        JR      Z,GridGeometryEGA112
        
        LD      A,80
        LD      (Grid_Width112),A
        LD      A,25
        LD      (Grid_Height112),A
        JR      GridGeometryReady112

GridGeometrySinclair112:
        LD      A,32
        LD      (Grid_Width112),A
        LD      A,24
        LD      (Grid_Height112),A
        JR      GridGeometryReady112

GridGeometryEGA112:
        LD      A,40
        LD      (Grid_Width112),A
        LD      A,25
        LD      (Grid_Height112),A

GridGeometryReady112:
        LD      HL,Text_ModePrefix112
        LD      C,0
        LD      D,0
        CALL    PrintString112
        
        LD      A,(Current_Mode_Index)
        ADD     A,A
        LD      E,A
        LD      D,0
        LD      HL,Mode_Name_Pointers
        ADD     HL,DE
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        EX      DE,HL
        LD      C,6
        LD      D,0
        CALL    PrintString112

        LD      A,32
        LD      (Demo_Character112),A
        LD      A,1
        LD      (Demo_Row112),A

DemoRowLoop112:
        XOR     A
        LD      (Demo_Column112),A

DemoColumnLoop112:
        LD      A,(Demo_Column112)
        LD      C,A
        LD      A,(Demo_Row112)
        LD      D,A

        LD      A,(Demo_Row112)
        LD      B,A
        LD      A,(Grid_Height112)
        DEC     A
        CP      B
        JR      Z,DrawBottomRuler112

        LD      A,(Demo_Column112)
        LD      B,A
        LD      A,(Grid_Width112)
        DEC     A
        CP      B
        JR      Z,DrawRightRuler112

        LD      A,(Demo_Character112)
        JR      DrawGridCell112

DrawBottomRuler112:
        LD      A,(Demo_Column112)
        INC     A
        CALL    Modulo10_112
        OR      A
        LD      A,'-'
        JR      NZ,DrawGridCell112
        LD      A,'0'
        JR      DrawGridCell112

DrawRightRuler112:
        LD      A,(Demo_Row112)
        INC     A
        CALL    Modulo10_112
        OR      A
        LD      A,'|'
        JR      NZ,DrawGridCell112
        LD      A,'0'

DrawGridCell112:
        CALL    PrintChar112

        LD      A,(Demo_Character112)
        INC     A
        CP      127
        JR      C,GridCharReady112
        LD      A,32
GridCharReady112:
        LD      (Demo_Character112),A

        LD      A,(Demo_Column112)
        INC     A
        LD      (Demo_Column112),A
        LD      B,A
        LD      A,(Grid_Width112)
        CP      B
        JR      NZ,DemoColumnLoop112

        LD      A,(Demo_Row112)
        INC     A
        LD      (Demo_Row112),A
        LD      B,A
        LD      A,(Grid_Height112)
        CP      B
        JP      NZ,DemoRowLoop112

        LD      HL,Debug_ScreenDrawn112
        CALL    DebugPrintString112
        RET

Modulo10_112:
        PUSH    BC
        LD      B,10
Modulo10Loop112:
        CP      B
        JR      C,Modulo10Done112
        SUB     B
        JR      Modulo10Loop112
Modulo10Done112:
        POP     BC
        RET

PrintString112:
        LD      A,(HL)
        OR      A
        RET     Z
        PUSH    HL
        CALL    PrintChar112
        POP     HL
        INC     HL
        INC     C
        JR      PrintString112

PrintChar112:
        PUSH    BC
        PUSH    DE
        PUSH    HL
        LD      (Temp_Character112),A
        LD      A,C
        LD      (Temp_X112),A
        LD      A,D
        LD      (Temp_Y112),A

        LD      A,(Current_Mode_Index)
        CP      3
        JR      Z,PrintCharATMText112

        LD      A,(Temp_Character112)
        CP      32
        JP      C,PrintCharDone112
        SUB     32
        LD      L,A
        LD      H,0
        ADD     HL,HL
        ADD     HL,HL
        ADD     HL,HL
        LD      DE,Font88_112
        ADD     HL,DE
        LD      (FontPointer112),HL

        XOR     A
        LD      (GlyphLine112),A

GlyphLineLoop112:
        LD      HL,(FontPointer112)
        LD      A,(HL)
        LD      (Temp_FontByte112),A
        INC     HL
        LD      (FontPointer112),HL

        LD      A,(Current_Mode_Index)
        OR      A
        CALL    Z,RenderGlyph_Standard112
        LD      A,(Current_Mode_Index)
        CP      1
        CALL    Z,RenderGlyph_ATM640112
        LD      A,(Current_Mode_Index)
        CP      2
        CALL    Z,RenderGlyph_ATMEGA112

        LD      A,(GlyphLine112)
        INC     A
        LD      (GlyphLine112),A
        CP      8
        JP      NZ,GlyphLineLoop112

        LD      A,(Current_Mode_Index)
        OR      A
        CALL    Z,RenderAttributes_Standard112
        JR      PrintCharDone112

PrintCharATMText112:
        CALL    RenderChar_ATMText112

PrintCharDone112:
        POP     HL
        POP     DE
        POP     BC
        RET

ClearVideoMemory112:
        LD      A,(Current_Mode_Index)
        OR      A
        JP      Z,ClearVideoMemory_Standard112
        JP      ClearVideoMemory_ATM112

VideoModeRegisterTable112:
        DB 3,0                  ; Sinclair 256x192
        DB 2,0                  ; ATM 640x200 Multicolor
        DB 0,0                  ; ATM EGA 320x200
        DB 6,0                  ; ATM Text 80x25
=======
; PROJECT112 MODE CYCLE
; 0 ZX Spectrum 256x192, 1 ATM 640x200, 2 EGA 320x200, 3 text 80x25.
; Space cycles through all four modes and returns to the native Spectrum mode.

SwitchToNextVideoMode:
        LD A,(Current_Mode_Index)
        INC A
        CP 4
        JR C,ModeIndexReady112
        XOR A
ModeIndexReady112:
        LD (Current_Mode_Index),A
        OR A
        JR Z,RestoreSinclairMemoryMap112

        ; ATM video pages: RAM page 5 at $4000, RAM page 1 at $C000.
        LD A,$7A
        LD BC,$7FF7
        OUT (C),A
        LD A,$7E
        LD BC,$FFF7
        OUT (C),A
        JR ApplyVideoRegister112

RestoreSinclairMemoryMap112:
        ; Restore RAM page 0 at $C000. Page 5 remains visible at $4000.
        LD A,$7F
        LD BC,$FFF7
        OUT (C),A
        XOR A
        LD BC,$7FFD
        OUT (C),A

ApplyVideoRegister112:
        LD A,(Current_Mode_Index)
        ADD A,A
        LD E,A
        LD D,0
        LD HL,VideoModeRegisterTable112
        ADD HL,DE
        LD A,(HL)
        OR $C0
        LD BC,$FF77
        OUT (C),A
        LD HL,Debug_ModeApplied112
        CALL DebugPrintString112
        CALL DrawDemoScreen
        JP MainLoop112

VideoModeRegisterTable112:
        DB 3,0
        DB 2,0
        DB 0,0
        DB 6,0
>>>>>>> f8f5905ba455aa6029ffa95e58d48fa5c5a90e7e
