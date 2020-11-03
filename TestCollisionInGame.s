CheckCollisions:

    lea     Monsters,a0

.loopmonsters
    move.w  (a0)+,d0            ; x in d0

    cmpi.w  #$ffff,d0      ; E' fine lista?
    beq.s   .fineloopmonsters

    move.w  (a0)+,d1            ; y in d0
    add.l   #2,a0               ; Salto il tipo di mostro che non mi interessa
    move.w  (a0),d2            ; vita del mostro in d2

; E' un mostro ancora in vita?
    tst.w   d2
    beq.s   .loopmonsters       ; Se si passo al prossimo

; E' in vita, prendo la posizione del proiettile
    move.w  ShipBulletX,d2      ; xp in d2
    move.w  ShipBulletY,d3      ; yp in d3

    move.w	#(16/2)+(16/2),d4   ; larghezza boundaries mostro e proiettile
	move.w	#(16/2)+(9/2),d5   ; altezza boundaries mostro e proiettile

    sub.w   d2,d0               ; x mostro - x proiettile = differenza orizzontale vertici sup sx
    bpl.s   .nonnegX            ; Se non è negativo salta
    neg.w   d0                  ; Se è negativo prendo il valore assoluto
.nonnegX
    cmp.w   d4,d0               ; Confronto con la larghezza boundary
    bhi.s   .nocoll             ; Se d0 > d4 non c'è collisione orizzontale, e quindi non c'è
                                ; alcuna collisione => esce.

                                ; Se invece c'è un intersecamento orizzontale, controllo che
                                ; ci sia anche quello verticale
    sub.w   d3,d1               ; y mostro - y proiettile
    bpl.s   .nonnegY            ; Se non è negativo salta
    neg.w   d1                  ; Se è negativo prendo il valore assoluto

.nonnegY
    cmp.w   d5,d1               ; Confronto con l'altezza boundary
                                ; A questo punto se il flag N (3) dello Status Register (SR)
                                ; E' 1 allora c'è stata collisione
    bpl.s	.nocoll
; Collisione!!!

    move.w  #$0fff,$0180

; Settare il mostro in stato esplosivo

    move.w  #0,(a0)

    rts
.nocoll
    add.l   #2,a0
    bra.s   .loopmonsters


.fineloopmonsters
    rts



; Fila mostri verdi
GreenRow:
    dc.w    8
    dc.w    40
    dc.w    0
    dc.w    1

    dc.w    8+(16*2)
    dc.w    40
    dc.w    0
    dc.w    1

    dc.w    8+(16*4)
    dc.w    40
    dc.w    0
    dc.w    1

    dc.w    8+(16*6)
    dc.w    40
    dc.w    0
    dc.w    1

    dc.w    8+(16*8)
    dc.w    40
    dc.w    0
    dc.w    1

    dc.w    8+(16*10)
    dc.w    40
    dc.w    0
    dc.w    1

    dc.w    8+(16*12)
    dc.w    40
    dc.w    0
    dc.w    1

    dc.w    8+(16*14)
    dc.w    40
    dc.w    0
    dc.w    1

    dc.w    8+(16*16)
    dc.w    40
    dc.w    0
    dc.w    1


; Fila mostri rossi
RedRow:
    dc.w    8
    dc.w    70
    dc.w    1
    dc.w    1

    dc.w    8+(16*2)
    dc.w    70
    dc.w    1
    dc.w    1

    dc.w    8+(16*4)
    dc.w    70
    dc.w    1
    dc.w    1

    dc.w    8+(16*6)
    dc.w    70
    dc.w    1
    dc.w    1

    dc.w    8+(16*8)
    dc.w    70
    dc.w    1
    dc.w    1

    dc.w    8+(16*10)
    dc.w    70
    dc.w    1
    dc.w    1

    dc.w    8+(16*12)
    dc.w    70
    dc.w    1
    dc.w    1

    dc.w    8+(16*14)
    dc.w    70
    dc.w    1
    dc.w    1

    dc.w    8+(16*16)
    dc.w    70
    dc.w    1
    dc.w    1

; Fila mostri gialli
YellowRow:
    dc.w    8
    dc.w    100
    dc.w    2
    dc.w    1

    dc.w    8+(16*2)
    dc.w    100
    dc.w    2
    dc.w    1

    dc.w    8+(16*4)
    dc.w    100
    dc.w    2
    dc.w    1

    dc.w    8+(16*6)
    dc.w    100
    dc.w    2
    dc.w    1

    dc.w    8+(16*8)
    dc.w    100
    dc.w    2
    dc.w    1

    dc.w    8+(16*10)
    dc.w    100
    dc.w    2
    dc.w    1

    dc.w    8+(16*12)
    dc.w    100
    dc.w    2
    dc.w    1

    dc.w    8+(16*14)
    dc.w    100
    dc.w    2
    dc.w    1

    dc.w    8+(16*16)
    dc.w    100
    dc.w    2
    dc.w    1

    dc.w    $ffff


ShipBulletX:
    dc.w    0
ShipBulletY:
    dc.w    0

    