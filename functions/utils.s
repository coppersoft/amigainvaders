; ATTENZIONE: Sovrascrive d0!
; d0 : srcX
; d1 : srcY
; d2 : dstX
; d3 : dstY
; d4 : src box width/2 + dst box width/2
; d5 : src box height/2 + dst box height/2
; d0 : 1 se collide, 0 se non collide

BoundaryCheck:

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
    move.w  #1,d0
    rts
.nocoll
    move.w  #0,d0
    rts
; --------------


; d0: valore decimale fino a 65535
; a0: Destinazione (6 byte)
DecToStr:

;	move.l	d0,d1
;	divu.l	#100000,d1
;	move.b	d1,(a0)+
;	mulu.l	#100000,d1
;	sub.l	d1,d0

; ---

	move.l	d0,d1
	divu.w	#10000,d1
	move.b	d1,(a0)+
	mulu.w	#10000,d1
	sub.l	d1,d0

; ----

	move.l	d0,d1
	divu.w	#1000,d1
	move.b	d1,(a0)+
	mulu.w	#1000,d1
	sub.l	d1,d0

; ----

	move.l	d0,d1
	divu.w	#100,d1
	move.b	d1,(a0)+
	mulu.w	#100,d1
	sub.l	d1,d0

; ----

	move.l	d0,d1
	divu.w	#10,d1
	move.b	d1,(a0)+
	mulu.w	#10,d1
	sub.l	d1,d0

	move.b	d0,(a0)

	rts

SwitchBuffers:

    movem.l d0-d1/a0,-(SP)

    move.l  draw_buffer,d0
    move.l  view_buffer,draw_buffer
    move.l  d0,view_buffer

    ; Setto CINQUE bitplane 

    lea     Bplpointers,a0 
;    move.l  #Bitplanes,d0

    moveq   #5-1,d1
PuntaBP:
    move.w  d0,6(a0)
    swap    d0 
    move.w  d0,2(a0) 
    swap    d0
    addq.l  #8,a0
    addi.l  #44,d0
    dbra    d1,PuntaBP

    movem.l (SP)+,d0-d1/a0

    rts

ShowLifes:
    ; Visualizzo il numero di vite, in entrambi i buffer
    move.l  draw_buffer,a0
    bsr.w   DrawLifes

    move.l  view_buffer,a0
    bsr.w   DrawLifes

    rts

; Routine per la stampa del punteggio
; CPU based, non blitter
ScoreStart = (44*10*5)+33

DrawScore:

    move.w  Score,d0
    lea     ScoreStr,a0

    bsr.w   DecToStr            ; Converto il valore decimale in stringa

    lea     ScoreStr,a0

    move.l  draw_buffer,a4      ; Me li salvo per i successivi loop
    move.l  view_buffer,a5

    move.l  #0,d2               ; Contatore cifra da stampare

    move.l  #5-1,d3             ; numero di cifre

.drawscoreloop:

    move.l  a4,a1               
    move.l  a5,a2

    add.l   #ScoreStart,a1
    add.l   #ScoreStart,a2

    add.l   d2,a1               ; mi sposto di un byte per ogni cifra
    add.l   d2,a2

    move.l  #0,d0

    move.b  (a0)+,d0            ; Prendo la cifra corrente in d0

    lea     Digits,a3           ; Font delle cifre in a3
    mulu.w  #7*5,d0             ; Moltiplico per l'altezza del font * 5 bitplane
    add.l   d0,a3               ; Trovo la posizione iniziale della cifra

    move.w  #(7*5)-1,d1         ; 7 byte * 5 bitplane da copiare
.drawsingledigitloop:

    move.b  (a3),(a1)
    move.b  (a3)+,(a2)
    add.l   #44,a1              ; Equivalente del modulo del blitter
    add.l   #44,a2
    dbra    d1,.drawsingledigitloop

    addq.l  #1,d2               ; Passo alla prossima cifra
    dbra    d3,.drawscoreloop

    rts

; Controllo se almeno un mostro è arrivato al margine
; in d2 0 se no, 1 se sì
CheckMonstersOnBottom:
    lea     Monsters,a0
    move.l  #0,d2
.loopmonsters:
    cmpi.w  #$ffff,(a0)
    beq.s   .fineloopmonsters
    addq.w  #2,a0
    move.w  (a0)+,d0     ; Posizione Y in d0
    addq.w  #2,a0
    move.w  (a0)+,d1     ; Vivo o morto in d1

    tst.w   d1
    beq.s   .loopmonsters   ; Se è morto passo al prossimo

    cmpi.w  #256-32,d0
    bne.s   .loopmonsters   ; Se non è arrivato al margine passo al prossimo
    move.w  #1,d2

.fineloopmonsters:
    rts