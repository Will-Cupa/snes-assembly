;INCLUDE FILES

.include "memap.asm" ONCE
.include "header.asm" ONCE
.include "interruptVector.asm" ONCE

sprite :
.incbin "Sprites.vra"

palette :
.incbin "SpriteColors.pal"

; these are aliases for the Memory Mapped Registers we will use
INIDISP     = $2100     ; inital settings for screen
OBJSEL      = $2101     ; object size $ object data area designation
MSD         = $212c     ; main screen designation
NMITIMEN    = $4200     ; enable flaog for v-blank
RDNMI       = $4210     ; read the NMI flag status

; address for accessing OAM
OAMADDL     = $2102     ; low byte (8 bits Register)
OAMADDH     = $2103     ; high byte (8 bits Register)

OAMDATA     = $2104     ; data for OAM write

VMAINC      = $2115     ; VRAM address increment value designation

; address for VRAM read and write
VMADDL      = $2116     ; low byte (8 bits Register)
VMADDH      = $2117     ; high byte (8 bits Register)

; data for VRAM write
VMDATAL     = $2118     ; low byte (8 bits Register)
VMDATAH     = $2119     ; high byte (8 bits Register)

CGADD       = $2121     ; address for CGRAM read and write
CGDATA      = $2122     ; data for CGRAM write

SCREENH = 224
SCREENW = 256

.BANK 0 SLOT 0

EmptyHandler :    ; Needed to satisfy interrupt definition in "interruptVector.asm"
    RTI

VBlank :         ; Needed to satisfy interrupt definition in "interruptVector.asm"
    RTI

prog :
    SEI                     ; disable interrupt
    CLC                     ; clear carry flag
    XCE                     ; switch the 65816 to native (16-bit mode)

    LDA #$8f                ; force v-blanking (draw nothing)
    STA INIDISP             ; set initial display settings to v-blank
    STZ NMITIMEN            ; stop NMI interrupt

    lda #%00000001     ; Mode 1, 8x8 tiles
    sta $2105

    lda #$80            ; Increment after accessing VRAM, increment by 1 byte
    sta VMAINC

    lda #$00
    sta OBJSEL

    ;send sprite to VRAM
    STZ VMADDL              ; set the VRAM address to $0000 bc it is used as an offset/counter
    STZ VMADDH

    LDX #$00                ; set register X to zero, we will use X as a loop counter and offset

    VRAMLoop:

        LDA sprite.w, X       ; get bitplane 0/2 byte from the sprite data (.w because its address use 16bits (word))
        STA VMDATAL             ; write the byte in A to low byte VRAM
        INX                   ; increment counter/offset
        LDA sprite.w, X       ; get bitplane 1/3 byte from the sprite data
        STA VMDATAH             ; write the byte in A to high byte VRAM
        INX                     ; increment counter/offset
        CPX #128                  ; check whether we have written 128 bytes to VRAM
        BCC VRAMLoop            ; if X is smaller than 128, continue the loop
    ; transfer CGRAM data
    LDA #128
    STA CGADD               ; set CGRAM address to 128 (second half of its registers)
    LDX #$00                ; set X to zero, use it as loop counter and offset
    
    CGRAMLoop:
        LDA palette.w, X        ; get the color low byte
        STA CGDATA              ; store it in CGRAM
        INX                     ; increase counter/offset
        LDA palette.w, X        ; get the color high byte
        STA CGDATA              ; store it in CGRAM
        INX                     ; increase counter/offset
        CPX #32                ; check whether 32 bytes were transfered (size of the palette)
        BCC CGRAMLoop           ; if not, continue loop
    
    ; set up OAM data              
    stz OAMADDL             ; set the OAM address ...
    stz OAMADDH             ; ...at $0000

    ; OAM data for first sprite (OAM address is auto-incremented by PPU)
    lda # (SCREENW/2 - 4)       ; horizontal position of first sprite
    sta OAMDATA
    lda # (SCREENH/2 - 4)       ; vertical position of first sprite
    sta OAMDATA
    lda #$00                    ; name of first sprite
    sta OAMDATA
    lda #$00                    ; no flip, prio 0, palette 0
    sta OAMDATA
    ; OAM data for second sprite
    lda # (SCREENW/2 + 4)           ; horizontal position of second sprite
    sta OAMDATA
    lda # (SCREENH/2 - 4)       ; vertical position of second sprite
    sta OAMDATA
    lda #$01                ; name of second sprite
    sta OAMDATA
    lda #$00                ; no flip, prio 0, palette 0
    sta OAMDATA
    ; OAM data for third sprite
    lda # (SCREENW/2 - 4)       ; horizontal position of third sprite
    sta OAMDATA
    lda # (SCREENH/2 + 4)           ; vertical position of third sprite
    sta OAMDATA
    lda #$02                ; name of third sprite
    sta OAMDATA
    lda #$00                ; no flip, prio 0, palette 0
    sta OAMDATA
    ; OAM data for fourth sprite
    lda # (SCREENW/2 + 4)           ; horizontal position of fourth sprite
    sta OAMDATA
    lda # (SCREENH/2 + 4)           ; vertical position of fourth sprite
    sta OAMDATA
    lda #$03                ; name of fourth sprite
    sta OAMDATA
    lda #$00                ; no flip, prio 0, palette 0
    sta OAMDATA

    ; make Objects visible
    lda #$10
    sta MSD

    ; release forced blanking, set screen to full brightness
    lda #$0f
    sta INIDISP
    ; enable NMI, turn on automatic joypad polling
    lda #$81
    sta NMITIMEN

    jmp GameLoop            ; all initialization is done
    RTS         ; Termination


GameLoop:
        wai                     ; wait for NMI / V-Blank

        ; here we would place all of the game logic
        ; and loop forever

        jmp GameLoop

NMIHandler:
        lda RDNMI               ; read NMI status, acknowledge NMI

        ; this is where we would do graphics update

        rti

.include "footer.asm" ONCE