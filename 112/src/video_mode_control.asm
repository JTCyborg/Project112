; =========================================================================
; PROJECT112 — ATM TURBO 2+ v7.10 VIDEO MODE CONTROL
;
; ATM system port: #FF77 (full I/O address).
; The low byte #77 selects the system port; BC addressing is required
; because the high byte of the I/O address must remain #FF while A carries
; the port data. OUT (#77),A is NOT equivalent: it forms A:#77.
;
; Mode bits D2..D0:
;   3 = Sinclair 256x192
;   2 = 640x200 hardware multicolor
;   0 = 320x200 EGA, 16 colors
;   6 = 80x25 hardware text
;
; D3=0: 3.5 MHz; D4=0 reserved; D5=0 HSYNC IRQ disabled;
; D6=0 keep 8031 keyboard controller enabled; D7=1 on v7.10.
;
; Important: the actual mode transition instruction sequence is isolated
; in a <=32-byte routine aligned to 256 bytes. Do not move this stub or
; expand it without rechecking the ATM address-line aliasing restriction.
; =========================================================================

SwitchToNextVideoMode:
        LD      A,(Current_Mode_Index)
        INC     A
        CP      Mode_Count
        JR      C,ATMModeIndexReady112
        XOR     A
ATMModeIndexReady112:
        LD      (Current_Mode_Index),A
        LD      L,A
        LD      H,0
        LD      DE,ATM_Mode_Bytes112
        ADD     HL,DE
        LD      A,(HL)
        OR      $80
        CALL    ATM_ModeSwitch112
        CALL    DrawDemoScreen
        RET

ApplyVideoMode:
        LD      A,(Current_Mode_Index)
        LD      L,A
        LD      H,0
        LD      DE,ATM_Mode_Bytes112
        ADD     HL,DE
        LD      A,(HL)
        OR      $80
        JP      ATM_ModeSwitch112

; This routine is deliberately kept short and page-aligned.
        ALIGN   256
ATM_ModeSwitch112:
        LD      BC,$FF77
        OUT     (C),A
        RET

Mode_Count             EQU 4
ATM_Mode_Bytes112:
        DB      3                       ; 0: Sinclair 256x192
        DB      2                       ; 1: 640x200 hardware multicolor
        DB      0                       ; 2: 320x200 EGA 16-color
        DB      6                       ; 3: 80x25 hardware text
