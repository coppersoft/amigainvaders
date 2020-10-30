; d0 = 1 right, 0 left
MoveAllMonstersHorizontally:

    lea     Monsters,a0
.loopmonsters_h
    move.w  (a0),d1
    cmpi.w  #$ffff,d1      ; E' fine lista?
    beq.s   .fineloopmonsters_h

    tst.w   d0             ; E' a sinistra?
    beq.s   .sinistra
    addi.w  #1,d1
    bra.s   .nonsinistra
.sinistra
    subi.w  #1,d1
.nonsinistra
    move.w  d1,(a0)

; Stranissimo, il vasm non riconosce addi.w sui registri indirizzo... Mah...
    add.w  #8,a0           ; Prossimo mostro
    bra.s   .loopmonsters_h

.fineloopmonsters_h
    rts

Monsters:

; Fila mostri verdi

    dc.w    16
    dc.w    40
    dc.w    0
    dc.w    1

    dc.w    16*3
    dc.w    40
    dc.w    0
    dc.w    1

    dc.w    16*5
    dc.w    40
    dc.w    0
    dc.w    1

    dc.w    16*7
    dc.w    40
    dc.w    0
    dc.w    1

    dc.w    16*9
    dc.w    40
    dc.w    0
    dc.w    1

    dc.w    16*11
    dc.w    40
    dc.w    0
    dc.w    1

    dc.w    16*13
    dc.w    40
    dc.w    0
    dc.w    1

    dc.w    16*15
    dc.w    40
    dc.w    0
    dc.w    1

    dc.w    16*17
    dc.w    40
    dc.w    0
    dc.w    1

; Fila mostri rossi

    dc.w    16
    dc.w    70
    dc.w    1
    dc.w    1

    dc.w    16*3
    dc.w    70
    dc.w    1
    dc.w    1

    dc.w    16*5
    dc.w    70
    dc.w    1
    dc.w    1

    dc.w    16*7
    dc.w    70
    dc.w    1
    dc.w    1

    dc.w    16*9
    dc.w    70
    dc.w    1
    dc.w    1

    dc.w    16*11
    dc.w    70
    dc.w    1
    dc.w    1

    dc.w    16*13
    dc.w    70
    dc.w    1
    dc.w    1

    dc.w    16*15
    dc.w    70
    dc.w    1
    dc.w    1

    dc.w    16*17
    dc.w    70
    dc.w    1
    dc.w    1

; Fila mostri gialli

    dc.w    16
    dc.w    100
    dc.w    2
    dc.w    1

    dc.w    16*3
    dc.w    100
    dc.w    2
    dc.w    1

    dc.w    16*5
    dc.w    100
    dc.w    2
    dc.w    1

    dc.w    16*7
    dc.w    100
    dc.w    2
    dc.w    1

    dc.w    16*9
    dc.w    100
    dc.w    2
    dc.w    1

    dc.w    16*11
    dc.w    100
    dc.w    2
    dc.w    1

    dc.w    16*13
    dc.w    100
    dc.w    2
    dc.w    1

    dc.w    16*15
    dc.w    100
    dc.w    2
    dc.w    1

    dc.w    16*17
    dc.w    100
    dc.w    2
    dc.w    1

    dc.w    $ffff
