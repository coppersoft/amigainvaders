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


; d0: valore decimale fino a 999999
; a0: Destinazione (6 byte)
;DecToStr:

;	move.l	d0,d1
;	divu.l	#100000,d1
;	move.b	d1,(a0)+
;	mulu.l	#100000,d1
;	sub.l	d1,d0

; ---

;	move.l	d0,d1
;	divu.l	#10000,d1
;	move.b	d1,(a0)+
;	mulu.l	#10000,d1
;	sub.l	d1,d0

; ----

;	move.l	d0,d1
;	divu.l	#1000,d1
;	move.b	d1,(a0)+
;	mulu.l	#1000,d1
;	sub.l	d1,d0

; ----

;	move.l	d0,d1
;	divu.l	#100,d1
;	move.b	d1,(a0)+
;	mulu.l	#100,d1
;	sub.l	d1,d0

; ----

;	move.l	d0,d1
;	divu.l	#10,d1
;	move.b	d1,(a0)+
;	mulu.l	#10,d1
;	sub.l	d1,d0

;	move.b	d0,(a0)

;	rts

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
    addi.l  #40,d0
    dbra    d1,PuntaBP

    movem.l (SP)+,d0-d1/a0

    rts

AspettaUnSecondo:

    move.l  #50,d0

.aspetta
    bsr.w   wframe
    dbra    d0,.aspetta
    rts