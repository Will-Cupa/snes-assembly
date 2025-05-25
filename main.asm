;INCLUDE FILES

.include "memap.asm" ONCE
.include "header.asm" ONCE
.include "interruptVector.asm" ONCE

sprite :
.incbin "sprites/lulu.bin"

palette :
.incbin "sprites/lulu.pal"

; these are aliases for the Memory Mapped Registers we will use
INIDISP     = $2100     ; inital settings for screen
OBJSEL      = $2101     ; object size object data area designation
MSD         = $212c     ; main screen designation
NMITIMEN    = $4200     ; enable flaog for v-blank
RDNMI       = $4210     ; read the NMI flag status

; address for accessing OAM
OAMADDL     = $2102     ; low byte (8 bits Register)
OAMADDH     = $2103     ; high byte (8 bits Register)

OAMDATA     = $2104     ; data for OAM write

VMAINC      = $2115     ; VRAM address increment value designation

HOR_SPEED   = $0300     ; the horizontal speed
VER_SPEED   = $0301     ; the vertical speed
OAMMIRROR   = $0400     ; location of OAMRAM mirror in WRAM

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

;----- Game Constants ----------------------------------------------------------
    ; we use these constants to check for collisions with the screen boundaries
SCREEN_LEFT     = $00   ; left screen boundary = 0
SCREEN_RIGHT    = $ff   ; right screen boundary = 255
SCREEN_TOP      = $00   ; top screen boundary = 0 
SCREEN_BOTTOM   = $df   ; bottom screen boundary = 223
    ; a simple constant to define the sprite movement speed 
SPRITE_SPEED    = $02   ; the sprites will move 2 pixel per frame
    ; this makes the code a bit more readable
SPRITE_SIZE     = $08   ; sprites are 8 by 8 pixel
OAMMIRROR_SIZE  = $0220 ; OAMRAM can hold data for 128 sprites, 4 bytes each

.BANK 0 SLOT 0

EmptyHandler :    ; Needed to satisfy interrupt definition in "interruptVector.asm"
    RTI

VBlank :         ; Needed to satisfy interrupt definition in "interruptVector.asm"
    RTI

ResetHandler :
    SEI                     ; disable interrupt
    CLC                     ; clear carry flag
    XCE                     ; switch the 65816 to native (16-bit mode)

    rep #$10                ; set X and Y to 16-bit
    sep #$20                ; set A to 8-bit

    LDA #$8f                ; force v-blanking (draw nothing)
    STA INIDISP             ; set initial display settings to v-blank
    STZ NMITIMEN            ; stop NMI interrupt

    ; set the stack pointer to $1fff
    ldx #$1fff              ; load X with $1fff
    txs                     ; copy X to stack pointer

    lda #$00                ; OAM properties
    sta OBJSEL

    TSX                     ; Save stack pointer

    PEA $0000               ; Push VRAM address onto the stack
    PEA sprite            ; Push Sprite address onto the stack

    LDA #$00        ; Needed to compare 16bit
    PHA 

    LDA #192                
    PHA                     ; Push byte count for the sprites onto the stack
    JSR LoadVRAM
    TXS

    TSX

    LDA #128
    PHA

    PEA palette

    LDA #$00        ; Needed to compare 16bit
    PHA

    LDA #32
    PHA
    JSR LoadCGRAM
    TXS
    
    JSR SetOAM



    ; make Objects visible
    lda #$10
    sta MSD

    ; release forced blanking, set screen to full brightness
    LDA #$0f
    STA INIDISP
    ; enable NMI, turn on automatic joypad polling
    LDA #$81
    STA NMITIMEN

    JMP GameLoop            ; all initialization is done
    RTS         ; Termination

LoadVRAM:
    ;send sprite to VRAM
    PHX             ; save stack address before
    ; create frame pointer
    PHD                     ; push Direct Register to stack
    TSC                     ; transfer Stack to... (via Accumulator)
    TCD                     ; ...Direct Register.

    ByteCount   = $07       ; number of bytes to transfer (go across 1 (pointer)+ 2 (old stack address 16bits)+ 2 (jump back address 16bits))
    SrcAddress  = $09       ; source address of sprite data (same + 2 (byte number 16bit))
    DestAddress = $0b       ; destination address in VRAM (same + 2 (src address 16bit))

    ; set destination address in VRAM, and address increment after writing to VRAM
    LDX DestAddress         ; load the destination pointer...
    STX VMADDL              ; ...and set VRAM address register to it
    
    LDA #$80                ; Increment after accessing VRAM, increment by 1 byte
    STA VMAINC

    LDY #$0000                ; set register Y to zero, we will use Y as a loop counter and offset

    VRAMLoop:

        LDA (SrcAddress,S), Y       ; get bitplane 0/2 byte from the sprite data
        STA VMDATAL             ; write the byte in A to low byte VRAM
        INY                   ; increment counter/offset
        LDA (SrcAddress,S), Y       ; get bitplane 1/3 byte from the sprite data
        STA VMDATAH             ; write the byte in A to high byte VRAM
        INY                     ; increment counter/offset
        CPY ByteCount           ; check whether we have written 192 bytes (= 6 sprites) to VRAM
                                ; 1 sprite is 8 by 8 and we have 4bpp (1/2 byte) so 8*8*(4/2) = 32 bytes for one sprite 
        BCC VRAMLoop            ; if X is smaller than 192, continue the loop

    pld                     ; restore caller's frame pointer
    plx                     ; restore old stack pointer

    RTS
    
LoadCGRAM:
    ;send sprite to VRAM
    PHX             ; save stack address before
    ; create frame pointer
    PHD                     ; push Direct Register to stack
    TSC                     ; transfer Stack to... (via Accumulator)
    TCD                     ; ...Direct Register.

    CGRAM_ByteCount   = $07       ; number of bytes to transfer (go across 1 (pointer)+ 2 (old stack address 16bits)+ 2 (jump back address 16bits))
    CGRAM_SrcAddress  = $09       ; source address of sprite data (same + 2 (byte number 16bit))
    CGRAM_DestAddress = $0b       ; destination address in VRAM (same + 2 (src address 16bit))

    
    LDA CGRAM_DestAddress         ; load the destination pointer...
    STA CGADD               ; set CGRAM address to 128 (second half of its registers)
    
    LDY #$0000                ; set X to zero, use it as loop counter and offset
    
    CGRAMLoop:
        LDA (CGRAM_SrcAddress, S), Y        ; get the color low byte
        STA CGDATA                         ; store it in CGRAM
        INY                                ; increase counter/offset
        LDA (CGRAM_SrcAddress, S), Y        ; get the color high byte
        STA CGDATA                         ; store it in CGRAM
        INY                                ; increase counter/offset
        CPY CGRAM_ByteCount               ; check whether 32 bytes were transfered (size of the palette)
        BCC CGRAMLoop                      ; if not, continue loop

    PLD
    PLX

    RTS

SetOAM:
    ; set up OAM data              
    stz OAMADDL             ; set the OAM address ...
    stz OAMADDH             ; ...at $0000

    ; OAM data for first sprite (OAM address is auto-incremented by PPU)
    lda # (SCREENW/2 - 12)       ; horizontal position of first sprite
    sta OAMDATA
    lda # (SCREENH/2 - 8)       ; vertical position of first sprite
    sta OAMDATA
    lda #$00                    ; name of first sprite
    sta OAMDATA
    lda #$00                    ; no flip, prio 0, palette 0
    sta OAMDATA
    ; OAM data for second sprite
    lda # (SCREENW/2 - 4)           ; horizontal position of second sprite
    sta OAMDATA
    lda # (SCREENH/2 - 8)       ; vertical position of second sprite
    sta OAMDATA
    lda #$01                ; name of second sprite
    sta OAMDATA
    lda #$00                ; no flip, prio 0, palette 0
    sta OAMDATA
    ; OAM data for third sprite
    lda # (SCREENW/2 + 4)       ; horizontal position of third sprite
    sta OAMDATA
    lda # (SCREENH/2 - 8)           ; vertical position of third sprite
    sta OAMDATA
    lda #$02                ; name of third sprite
    sta OAMDATA
    lda #$00                ; no flip, prio 0, palette 0
    sta OAMDATA
    ; OAM data for fourth sprite
    lda # (SCREENW/2 - 12)           ; horizontal position of fourth sprite
    sta OAMDATA
    lda # (SCREENH/2)           ; vertical position of fourth sprite
    sta OAMDATA
    lda #$03                ; name of fourth sprite
    sta OAMDATA
    lda #$00                ; no flip, prio 0, palette 0
    sta OAMDATA
    ; OAM data for fifth sprite
    lda # (SCREENW/2 - 4)           ; horizontal position of fourth sprite
    sta OAMDATA
    lda # (SCREENH/2)           ; vertical position of fourth sprite
    sta OAMDATA
    lda #$04                ; name of fourth sprite
    sta OAMDATA
    lda #$00                ; no flip, prio 0, palette 0
    sta OAMDATA
    ; OAM data for sixth sprite
    lda # (SCREENW/2 + 4)           ; horizontal position of fourth sprite
    sta OAMDATA
    lda # (SCREENH/2)           ; vertical position of fourth sprite
    sta OAMDATA
    lda #$05                ; name of fourth sprite
    sta OAMDATA
    lda #$00                ; no flip, prio 0, palette 0
    sta OAMDATA

    RTS

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