; Routine di puntamento sprite su uno schermo standard 320x256

; a1    Indirizzo dello sprite
; d0    Posizione verticale
; d1    Posizione orizzontale
; d2    Altezza
PointSprite:
    add.w   #$2c,d0         ; Aggiungi inizio schermo (vedi $dff08e DIWSTRT)
    move.b  d0,(a1)         ; Copio il byte in VSTART
    btst.l  #8,d0           ; Il bit 8 della posizione è settato?
    beq.s   .novstartset    ; Se no non lo setto
    bset.b  #2,3(a1)        ; Altrimenti setto il bit 2 di SPRCTL
    bra.s   .tovstop
.novstartset
    bclr.b  #2,3(a1)        ; Se non lo dovevo settare allora lo azzero
.tovstop
    add.w   d2,d0           ; Aggiunto l'altezza dello sprite
    move.b  d0,2(a1)        ; E la metto in VSTOP
    btst.l  #8,d0           ; Anche per VSTOP, stesso controllo di sopra
    beq.s   .novstopset
    bset.b  #1,3(a1)        ; Setto il bit 8 di VSTOP ovvero il bit 1 di SPRCTL
    bra.s   .vstopfin
.novstopset
    bclr.b  #1,3(a1)        ; Se non lo dovevo settare allora lo azzero
.vstopfin
    add.w   #128,d1
    btst    #0,d1           ; Il bit basso della coordinata è zero?
    beq.s   .lowbitzero
    bset    #0,3(a1)        ; Se non lo è setto il bit 0 di SPRCTL, ovvero il bit basso di HSTART
    bra.s   .placecoords
.lowbitzero
    bclr    #0,3(a1)        ; Se lo è comunque lo azzero, come prima
.placecoords
    lsr     #1,d1           ; Tolgo il bit basso di HSTART
    move.b  d1,1(a1)        ; E lo setto in HSTART
    rts