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

        ; DOSEN уже открыт при старте и не сбрасывался.
        ; Не трогаем #FF77/#7FFD перед сменой режима: задаём только
        ; карту ATM и затем полный байт целевого видеорежима.

        ; После сброса конфигурации подключаем страницы видеопамяти ATM.
        LD      A,$7A                   ; RAM page 5 -> $4000-$7FFF
        LD      BC,$7FF7
        OUT     (C),A
        LD      A,$7E                   ; RAM page 1 -> $C000-$FFFF
        LD      BC,$FFF7
        OUT     (C),A
        JR      PrepareVideoRegister112

RestoreSinclairMemoryMap112:
        ; Сначала восстанавливаем физические страницы окон, пока ATM
        ; shadow-port decoder ещё работает. Системный Sinclair mode
        ; включаем последним, после завершения всех теневых OUT.
        LD      A,$7A                   ; Окно $4000 -> RAM page 5 (экран)
        LD      BC,$7FF7
        OUT     (C),A
        LD      A,$7F                   ; Окно $C000 -> RAM page 0
        LD      BC,$FFF7
        OUT     (C),A

        XOR     A
        LD      BC,$7FFD
        OUT     (C),A

        LD      A,$C3                   ; Sinclair 256x192
        LD      BC,$FF77
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
        OR      $C0                     ; Полный байт режима: VE1/VE0=1, прочие биты из таблицы

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
        ; Значения RG задаются заново, а не объединяются с прежним #FF77.
        ; Верхние VE1/VE0 добавляются в PrepareVideoRegister112.
        DB 3,0                  ; Sinclair 256x192 = #C3
        DB 2,0                  ; ATM 640x200 Multicolor = #C2
        DB 0,0                  ; ATM EGA 320x200 = #C0
        DB 6,0                  ; ATM Text 80x25 = #C6
