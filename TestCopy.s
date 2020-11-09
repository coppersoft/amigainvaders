NumberOfMonsters = 21 

    move.w  #(4*NumberOfMonsters)-1,d0                    ; 4 word per 21 mostri

    lea     MonstersStartPositions,a0
    lea     Monsters,a1

.copyloop
    move.w  (a0)+,(a1)+
    dbra    d0,.copyloop

Monsters:
   dcb.w    4*NumberOfMonsters,0

   dc.w    $ffff
MonstersStartPositions:
; Fila mostri verdi
GreenRow:
    dc.w    8
    dc.w    40
    dc.w    0
    dc.w    1

    dc.w    8+(14*3)
    dc.w    40
    dc.w    0
    dc.w    1

    dc.w    8+(14*6)
    dc.w    40
    dc.w    0
    dc.w    1

    dc.w    8+(14*9)
    dc.w    40
    dc.w    0
    dc.w    1

    dc.w    8+(14*12)
    dc.w    40
    dc.w    0
    dc.w    1

    dc.w    8+(14*15)
    dc.w    40
    dc.w    0
    dc.w    1

    dc.w    8+(14*18)
    dc.w    40
    dc.w    0
    dc.w    1


; Fila mostri rossi
RedRow:
    dc.w    8
    dc.w    70
    dc.w    1
    dc.w    1

    dc.w    8+(14*3)
    dc.w    70
    dc.w    1
    dc.w    1

    dc.w    8+(14*6)
    dc.w    70
    dc.w    1
    dc.w    1

    dc.w    8+(14*9)
    dc.w    70
    dc.w    1
    dc.w    1

    dc.w    8+(14*12)
    dc.w    70
    dc.w    1
    dc.w    1

    dc.w    8+(14*15)
    dc.w    70
    dc.w    1
    dc.w    1

    dc.w    8+(14*18)
    dc.w    70
    dc.w    1
    dc.w    1

; Fila mostri gialli
YellowRow:
    dc.w    8
    dc.w    100
    dc.w    2
    dc.w    1

    dc.w    8+(14*3)
    dc.w    100
    dc.w    2
    dc.w    1

    dc.w    8+(14*6)
    dc.w    100
    dc.w    2
    dc.w    1

    dc.w    8+(14*9)
    dc.w    100
    dc.w    2
    dc.w    1

    dc.w    8+(14*12)
    dc.w    100
    dc.w    2
    dc.w    1

    dc.w    8+(14*15)
    dc.w    100
    dc.w    2
    dc.w    1

    dc.w    8+(14*18)
    dc.w    100
    dc.w    2
    dc.w    1
