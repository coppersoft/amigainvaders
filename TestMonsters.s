DrawMonsters:
    
    lea     Monsters,a3
.loopmonsters:
    move.w  (a3)+,d0
    cmpi.w  #$ffff,d0      ; E' fine lista?
    beq.s   .fineloopmonsters

    move.w  (a3)+,d1        ; Copio posizione Y
    move.w  (a3)+,d5        ; Copio il tipo
    move.w  (a3)+,d6        ; Vivo o morto?

    cmp.w   #1,d6           ; E' vivo?
    bne.s   .nonvivo

    cmp.w   #0,d5           ; E' il mostro verde?
    bne.s   .nogreen
    lea     GreenMonster,a0
    lea     GreenMonsterMask,a0
    bra.s   .found
.nogreen
    cmp.w   #1,d5           ; E' il mostro rosso?
    bne.s   .nored
    lea     RedMonster,a0
    lea     RedMonsterMask,a0
    bra.s   .found
.nored
    lea     YellowMonster,a0        ; Allora è quello giallo
    lea     YellowMonsterMask,a0

.found
    
    move.w  #2,d2           ; Dimensione in word
    move.w  #16,d3          ; Altezza
    move.w  #5,d4           ; Numero bitplane

    ;bsr.w   BlitBob

.nonvivo

    bra.s   .loopmonsters

.fineloopmonsters:
    rts


GreenMonster:
    incbin "GreenMon.raw"
GreenMonsterMask:
    incbin "GreenMonMask.raw"
RedMonster:
    incbin "RedMon.raw"
RedMonsterMask:
    incbin "RedMonMask.raw"
YellowMonster:
    incbin "YellowMon.raw"
YellowMonsterMask:
    incbin "YellowMonMask.raw"

EVEN

Monsters:
    dc.w    16
    dc.w    16
    dc.w    0
    dc.w    1

    dc.w    16*3
    dc.w    16
    dc.w    1
    dc.w    1

    dc.w    16*5
    dc.w    16
    dc.w    2
    dc.w    1
    
    dc.w    $ffff
