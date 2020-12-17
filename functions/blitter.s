; Funzione di blittaggio con cookie cut semplicifata e ottimizzata per bob larghi 16+16 pixel (2 word)

; a0    Indirizzo Bob
; a1    Indirizzo Maschera
; a2    Indirizzo bitplane (interleaved)
; a3    Background

; d0    Posizione X
; d1    Posizione Y
; d3    Altezza in word totali

BlitBob16:
    movem.l d5-d7/a3,-(SP)

    tst     $dff002
.waitblit
    btst    #14-8,$dff002
    bne.s   .waitblit           ; Aspetto il blitter che finisce

    move.l  d0,d5           ; Mi salvo la posizione X in d5
    andi.l  #%00001111,d5   ; Prendo il valore dello shift
    lsr.l   #4,d0           ; Divido per 16 prendendo le word di cui spostarmi a destra
    lsl.l   #1,d0           ; Rimoltiplico per due per ottenere i byte

    move.l  #$0fe20000,d7  ; Dico al blitter che operazione effettuare, BLTCON

    lsl.l   #7,d5
    lsl.l   #5,d5
    or.l    d5,d7           ; Setto lo shift per il canale DMA B
    lsl.l   #7,d5
    lsl.l   #7,d5
    lsl.l   #2,d5
    
    or.l    d5,d7           ; Setto lo shift per il canale DMA A

    move.l  d7,$dff040      ; Dico al blitter che operazione effettuare, BLTCON


    move.l #$ffffffff,$dff044   ; maschera, BLTAFWM e BLTALWM

    move.l  a0,$dff050          ; Setto la sorgente su BLTAPTH
    move.l  a1,$dff04c          ; Setto la maschera su BLTBPTH

    mulu.w  #200,d1              ; Scendo di 40 byte per ogni posizione Y
    add.l   d0,d1               ; Gli aggiungo i byte di scostamento a destra della posizione X
    add.l   d1,a2               ; Offset con l'inizio dei bitplane
    add.l   d1,a3               ; In destinazione e background

    move.l  a3,$dff048          ; Setto lo sfondo su BLTCPTH
    move.l  a2,$dff054          ; Setto la destinazione su BLTDPTH

    ; Moduli per 32 pixel, 4 word

    move.w  #0,$dff064          ; Modulo zero per la sorgente BLTAMOD
    move.w  #0,$dff062          ; Modulo zero per la sorgente maschera BLTBMOD
    move.w  #36,$dff060          ; Modulo per il canale C con lo sfondo BLTCMOD
    move.w  #36,$dff066          ; Setto il modulo per il canale D di destiazione BLTDMOD

    lsl.w   #6,d3
    add.w   #2,d3

    move.w  d3,$dff058                   ; Setto le dimensioni e lancio la blittata

    movem.l (SP)+,d5-d7/a3

    rts

; ---------------------------------------------------------------

; Funzione di blitting universale con cookie cut

; a0    Indirizzo Bob
; a1    Indirizzo Maschera
; a2    Indirizzo bitplane (interleaved)

; d0    Posizione X
; d1    Posizione Y
; d2    Larghezza in word
; d3    Altezza
; d4    Numero bitplane

BlitBob:
    movem.l d5-d7,-(SP)

    tst     $dff002
.waitblit
    btst    #14-8,$dff002
    bne.s   .waitblit           ; Aspetto il blitter che finisce

    move.l  d0,d5           ; Mi salvo la posizione X in d5
    andi.l  #%00001111,d5   ; Prendo il valore dello shift
    lsr.l   #4,d0           ; Divido per 16 prendendo le word di cui spostarmi a destra
    lsl.l   #1,d0           ; Rimoltiplico per due per ottenere i byte

    move.l  #$0fe20000,d7  ; Dico al blitter che operazione effettuare, BLTCON

    lsl.l   #7,d5
    lsl.l   #5,d5
    or.l    d5,d7           ; Setto lo shift per il canale DMA B
    lsl.l   #7,d5
    lsl.l   #7,d5
    lsl.l   #2,d5
    
    or.l    d5,d7           ; Setto lo shift per il canale DMA A

    move.l  d7,$dff040      ; Dico al blitter che operazione effettuare, BLTCON


    move.l #$ffffffff,$dff044   ; maschera, BLTAFWM e BLTALWM

    move.l  a0,$dff050          ; Setto la sorgente su BLTAPTH
    move.l  a1,$dff04c          ; Setto la maschera su BLTBPTH

    mulu.w  #40,d1              ; Scendo di 40 byte per ogni posizione Y
    mulu.w  d4,d1               ; Per il numero dei bitplane
    add.l   d0,d1               ; Gli aggiungo i byte di scostamento a destra della posizione X
    add.l   d1,a2               ; Offset con l'inizio dei bitplane

    move.l  a2,$dff048          ; Setto lo sfondo su BLTCPTH
    move.l  a2,$dff054          ; Setto la destinazione su BLTDPTH

    ; Calcolo moduli

    lsl.l   #1,d2               ; Moltiplico d2 per due, per ottenere i byte della larghezza
    move.l  #40,d6              ; 40 in d6 (numero di byte per ogni riga)
    sub.l   d2,d6               ; 40 - d2*2 e trovo il modulo

    move.w  #0,$dff064          ; Modulo zero per la sorgente BLTAMOD
    move.w  #0,$dff062          ; Modulo zero per la sorgente maschera BLTBMOD
    move.w  d6,$dff060          ; Modulo per il canale C con lo sfondo BLTCMOD
    move.w  d6,$dff066          ; Setto il modulo per il canale D di destiazione BLTDMOD

    ; Bltsize: dimensione y * 64 + dim x

    mulu.w  d4,d3               ; Altezza * numero di bitplane
    lsl.l   #6,d3               ; Sposto l'altezza nei 10 bit alti di BLTSIZE

    lsr.l   #1,d2               ; Riporto la larghezza in word

    add.w   d2,d3
    move.w  d3,$dff058                   ; Setto le dimensioni e lancio la blittata

    movem.l (SP)+,d5-d7

    rts




; ---------------------------------------------------------------

; Funzione di copia semplice, senza cookie cut.

;   a0 = sorgente
;   a1 = destinazione
;   d0 = numero di righe
;   d1 = numero Bitplane
SimpleBlit:
    tst     $dff002
.waitblit
    btst    #14-8,$dff002
    bne.s   .waitblit           ; Aspetto il blitter che finisce

    ; 0 = shift nullo
    ; 9 = 1001: abilito solo i canali A e D
    ; f0 = minterm, copia semplice
    move.l  #$09f00000,$dff040  ; Dico al blitter che operazione effettuare, BLTCON

    move.l #$ffffffff,$dff044   ; maschera, BLTAFWM e BLTALWM

    move.l  a0,$dff050    ; Setto la sorgente su BLTAPTH
    move.l  a1,$dff054    ; Setto la destinazione su BLTDPTH
    move.w  #0,$dff064    ; Modulo zero per la sorgente BLTAMOD
    move.w  #0,$dff066    ; Setto il modulo per il canale D di destiazione BLTDMOD
    
    mulu.w  d1,d0         ; Moltiplico il numero di righe da copiare per i bitplane
    lsl.w   #6,d0
    addi.w  #20,d0        ; 320 pixel = 20 word in bltsize

    move.w  d0,$dff058  ; Dimensioni e blittata
    rts

; --------------------------------------------------------------------

; Funzione per pulire lo sfondo dell'astronave, solo canale D e minterm a 0
; Modifica: cancello l'intera striscia per evitare problemi di "scie" di 2 pixe
; dovuti al passaggio da un buffer all'altro nello switch del double buffering

CleanShipBackground:
    move.w  ShipBobX,d0

;    lsr.l   #4,d0           ; Divido per 16 prendendo le word di cui spostarmi a destra
;    lsl.l   #1,d0           ; Rimoltiplico per due per ottenere i byte

    move.l  draw_buffer,a0

    add.l   #ShipY*5*40,a0         

;    add.l   d0,a0

    tst     $dff002
.waitblit
    btst    #14-8,$dff002
    bne.s   .waitblit           ; Aspetto il blitter che finisce

;   0 = shift nullo
;   1 = 0001 abilito solo il canale D di destinazione, non devo copiare nulla
;   00 = minterm, cancella tutto
    move.l  #$01000000,$dff040    ; Dico al blitter che deve solamente pulire

    move.l  #$ffffffff,$dff044   ; maschera, BLTAFWM e BLTALWM

    move.l  a0,$dff054          ; Destinazione in BLTDPTH

;    move.w  #36,$dff066         ; Modulo canale Destinazione D
    move.w  #0,$dff066         ; Modulo canale Destinazione D

    move.w  #((16*5)*64)+20,$dff058      ; BLTSIZE
;    move.w  #((16*5)*64)+2,$dff058      ; BLTSIZE

    rts

; -------------------------------------------------

; Funzione per pulire lo sfondo del mostro colpito o dell'esplosione, chiamata
; immediatamente prima dell'inizio dell'animazione dell'esplosione

; d0 x
; d1 y
CleanBackground:

    lea     Background,a1
    move.l  draw_buffer,a2

    tst     $dff002
.waitblit
    btst    #14-8,$dff002
    bne.s   .waitblit           ; Aspetto il blitter che finisce

    mulu.w  #200,d1         ; Giù per 5 bitplane

    lsr.l   #4,d0           ; Divido per 16 prendendo le word di cui spostarmi a destra
    lsl.l   #1,d0           ; Rimoltiplico per due per ottenere i byte

    add.l   d0,d1           ; Aggiungo lo scostamento in byte
    add.l   d1,a1           ; Posiziono sorgente e destinazione sullo stesso offset
    add.l   d1,a2

    ; 0 = shift nullo
    ; 9 = 1001: abilito solo i canali A e D
    ; f0 = minterm, copia semplice
    move.l  #$09f00000,$dff040  ; Dico al blitter che operazione effettuare, BLTCON

    move.l #$ffffffff,$dff044   ; maschera, BLTAFWM e BLTALWM

    move.l  a1,$dff050    ; Setto la sorgente su BLTAPTH
    move.l  a2,$dff054    ; Setto la destinazione su BLTDPTH

    move.w  #4,$dff064    ; Modulo per la sorgente BLTAMOD
    move.w  #4,$dff066    ; Setto il modulo per il canale D di destiazione BLTDMOD

    move.w  #((16*5)*64)+18,$dff058

    rts

; Copia sfondo in entrambi i buffer
CopiaSfondo:

    movem.l d0/d1/a0/a1,-(SP)

    lea     Background,a0
    move.l  draw_buffer,a1
    move.w  #200,d0
    move.w  #5,d1
    bsr.w   SimpleBlit
    
    lea     Background,a0
    move.l  view_buffer,a1
    move.w  #200,d0
    move.w  #5,d1
    bsr.w   SimpleBlit

    lea     Background+(200*40*5),a0
    move.l  draw_buffer,a1
    add.l   #200*40*5,a1
    move.w  #55,d0
    move.w  #5,d1
    bsr.w   SimpleBlit
    
    lea     Background+(200*40*5),a0
    move.l  view_buffer,a1
    add.l   #200*40*5,a1
    move.w  #55,d0
    move.w  #5,d1
    bsr.w   SimpleBlit

    movem.l (SP)+,d0/d1/a0/a1
    rts

CopiaPannello:

     lea     Background,a0
     move.l  draw_buffer,a1
     move.w  #5,d0
     move.w  #26,d1
     bsr.w   SimpleBlit

     lea     Background,a0
     move.l  view_buffer,a1
     move.w  #5,d0
     move.w  #26,d1
     bsr.w   SimpleBlit

     rts

; a0    buffer dove scrivere
DrawLifes:

    move.l  a0,a1       ; me lo salvo per dopo

    tst     $dff002
.waitblit
    btst    #14-8,$dff002
    bne.s   .waitblit           ; Aspetto il blitter che finisce

; Prima pulisco lo sfondo del visualizzatore vite rimaste

;    move.l  draw_buffer,a0
    add.l  #(8*40*5)+2,a0      ; riga 8 seconda word  

; Cancellazione, quindi shift nullo e solo canale D di destinazione, minterm a 0
    move.l  #$01000000,$dff040
    move.l  #$ffffffff,$dff044      ; maschera

    move.l  a0,$dff054
    move.w  #(40-6),$dff066     ; Modulo canale D, salto 3 word

    move.w  #(10*5*64)+3,$dff058        ; BLTSIZE

; Copio il numero di vite

    move.w  Lifes,d0

    tst.w   d0
    beq.s   .nessunavita

    subq.w  #1,d0
    move.w  #0,d1                ; Byte di spostamento a destra per ogni vita da visualizzare
.lifesloop

    tst     $dff002
.waitblit2
    btst    #14-8,$dff002
    bne.s   .waitblit2           ; Aspetto il blitter che finisce

    lea     Life,a2

    move.l  a1,a0

    add.l   #(8*40*5)+2,a0      ; riga 8 seconda word
  
    add.l   d1,a0               

    move.l  #$09f00000,$dff040  ; Copia semplice, canali A e D

    move.l  a2,$dff050          ; Sorgente in BLTAPTH
    move.l  a0,$dff054          ; Destinazione in BLTPTH

    move.w  #0,$dff064          ; Modulo 0 per la sorgente
    move.w  #38,$dff066         ; Modulo 38 byte per la destinazione

    move.w  #(10*5*64)+1,$dff058         ; BLTSIZE

    addq.w  #2,d1
    dbra    d0,.lifesloop

.nessunavita

    rts

