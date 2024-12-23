.ORG $FFFA  ;location counter
    .DW $0000
    .DW $8000
    .DW $0000

.EMPTYFILL $00    ; Ensure unused space is filled with 0x00
.ORGA $1FFFF      ; Set the ROM size to 256 KB (2 Mbits)
.DB 0             ; Write a single byte to mark the end