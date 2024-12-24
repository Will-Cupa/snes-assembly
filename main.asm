;INCLUDE FILES

.include "memap.asm" ONCE
.include "header.asm" ONCE
.include "interruptVector.asm" ONCE

sprite :
.INCBIN "debug.bin"

palette :
.INCBIN "debug.pal"

.EQU z_HL   $20 ;define variables with adresses
.EQU z_L    $20
.EQU z_H    $21
.EQU z_HLU  $22

.EQU CursorX $40
.EQU CursorY $41

.BANK 0 SLOT 0

EmptyHandler    ; Needed to satisfy interrupt definition in "interruptVector.asm"
    RTI

VBlank:         ; Needed to satisfy interrupt definition in "interruptVector.asm"
    RTI

prog:
    RTS

.include "footer.asm" ONCE