	move.w	#5,d0
	move.w	#6,d1

	bsr.w	AddExplosion

	move.w  #7,d0
	move.w  #8,d1

	bsr.w	AddExplosion

	rts


; d0 x
; d1 y
AddExplosion:
    lea     ExplosionsList,a0
    lea     ExplosionsList,a1
    move.w  #0,d3
.looplist
    move.w  (a0),d2             ; Cerco la fine della lista
    cmpi.w  #$ffff,d2
    beq.s   .trovatafinelista
    add.w   #2,a0               ; Proseguo
;    add.w   #2,d3               ; E aggiorno il contatore di scostamento
    bra.s   .looplist
.trovatafinelista
.shift
    move.w  (a0),6(a0)
    cmp.l   a0,a1		; Se la lista era vuota shifto solo fine lista
    beq.s   .solofinelista
    move.w  -2(a0),4(a0)
    move.w  -4(a0),2(a0)
    move.w  -6(a0),(a0)
    sub.l   #6,a0
    cmp.l   a0,a1		; Sono in testa alla coda?
    bne.s   .shift		; Se si shifto altre 3 word

.solofinelista

    move.w  d0,(a0)+            ; Sostituisco il segnale di fine lista con la x
    move.w  d1,(a0)+            ; y
    move.w  #0,(a0)		; Primo fotogramma dell'animazione
    rts



ExplosionsList:
    dc.w    $ffff
    dcb.w   3*10,0  ; 10 dovrebbero bastare...  
