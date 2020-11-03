ShipY = 239
ShipSpeed = 2
ShipBulletTopYMargin = 28
ShipBulletSpeed = 2

    SECTION MyDemo,CODE_C

; Codice di partenza

; ====== BLOCCO DEL SISTEMA OPERATIVO E DEGLI INTERRUPT

init:
    ; Dobbiamo salvare la copperlist del sistema operativo, ma lo facciamo con una chiamata alla graphics.library
    ; (questo non me lo ricordavo, probabilmente stava nel startup.s di Randy
    ; Per aprire una library scrivo

    move.l  4.w,a6              ; execbase, il puntatore alla open library è sempre all'indirizzo 4 in memoria
                                ; non uso il # perché non voglio mettere 4 in a6, ma il contenuto dell'indirizzo 4.
                                ; Omettendo il # leggo un valore dalla memoria.
    clr.l   d0                  ; Clear d0, che è il version number

    ; ora devo dirgli quale libreria aprire, metto il puntatore del nome ascii della libreria in un registro indirizzo
    move.l  #gfxname,a1         ; Definito in fondo
    jsr     -408(a6)            ; -408 è l'offset della funzione oldopenlibrary

    ; Otteniamo il base pointer alla graphics.library in d0 e lo metto in un registro indirizzo ovviamente
    move.l  d0,a1
    move.l  38(a1),d4           ; Fetchiamo il current copper pointer e lo mettiamo in d4, all'uscita lo ripristineremo

    ; Chiudiamo la libreria, con la funzione closelibrary() sempre partendo da execbase
    jsr     -414(a6)

;   Mi salvo il precedente valore di INTENAR in modo da poter tornare al sistema operativo quando esco
;   E' quello read only http://amiga-dev.wikidot.com/hardware:intenar

    move    $dff01c,d5

; Salvo il valore di DMACON dal registro di lettura http://amiga-dev.wikidot.com/hardware:dmaconr
    move.w  $dff002,d3

; ===== FINE BLOCCO DEL SISTEMA OPERATIVO

; Mi salvo nello stack i registri usati per salvare lo stato del SO 

    movem.l	d3-d5,-(SP)

    bsr.w   START

; Recupero i registri salvati prima nello stack
    movem.l (SP)+,d3-d5


; ===== RIPRISTINO SISTEMA OPERATIVO

exit:
    ; Ripristino dmacon
    move.w  #$7fff,$dff096      ; Pulisco il regitro DMACON 0111111111111111  (il bit 15 è il control bit, quindi se è a 0 azzera tutti quelli che sono a 1)
    or.w    #$8200,d3           ; OR con 1000001000000000 per settare il bit 15 e il bit 9 DMAEN
    move.w  d3,$dff096          ; Ripristino il DMACON

    move.l  d4,$dff080          ; Ripristiniamo la copperlist originale del SO

    or      #$c000,d5           ; Setto a 1 il bit più significativo, quello di controllo, RIVEDERE PERCHE' E C000 E NON 8000
                                ; perché è 1100000000000000, devo riattivare il bit 14 (master interrupt) mettendogli 1 (bit 15 set/clr)
                                ; http://amiga-dev.wikidot.com/hardware:intenar
    move    d5,$dff09a          ; Ripristino l'INTENA come era prima di disattivare tutti gli interrupt

    moveq   #0,d0               ; No error code al sistema operativo

    rts

; ===== FINE RIPRISTINO SISTEMA OPERATIVO E USCITA






; ===== INIZIO CODICE 

START:

; E' meglio aspettare l'end of frame prima di smaneggiare con questi registri, in teoria dovrebbe sistemare lo sprite flickering
; ma a me non funziona proprio
    move.w  #$138,d0
    bsr.w   WaitRaster
    
    move.w  #$7fff,$dff09a           ; Disabilito tutti i bit in INTENA (interrupt enable)
    move.w  #$7fff,$dff09c          ; (Buona pratica:) Disabilito tutti i bit in INTREQ
    move.w  #$7fff,$dff09c          ; (Buona pratica:) Disabilito tutti i bit in INTREQ, faccio due volte per renderlo compatibile con A4000 che ha un bug

; Per disabilitare tutti i DMA completamente, facciamo qualcosa di simile a quanto fatto qui sopra con gli interrupt

    move.w  #$7fff,$dff096          ; Disabilito tutti i bit in DMACON

; Abilito per lo meno il copper, bitplanes

; DMACON dff096 DMA Control write (clear or set) http://amiga-dev.wikidot.com/hardware:dmaconr
;    move.w  #$87c0,$dff096          ; No sprite => 87c0 è 1000011111000000
                                    ; Il bit 5 è a 0 => Sprite Enable a 0
                                    ; Il bit 6 è a 1 => Blitter DMA Enable
                                    ; Il bit 7 è a 1 => Coprocessor DMA Enable
                                    ; Il bit 8 è a 1 => Bitplane DMA Enable
                                    ; Il bit 9 è a 1 => Enable all DMA Below ???
                                    ; Il bit 10 è a 1 => Blitter DMA priority, evita che la CPU rubi dei cicli mentre il blitter gira)
                                    ; Il bit 15 è a 1 => SET/CLR , stabilisce se i bit a 1 settano o cancellano

    move.w  #$87e0,$dff096      ; DMACON (write) 1000011111100000
                                ; 15 - Set Clear bit a 1 => i bit a 1 settano
                                ; 10 - BlitPRI a 1
                                ; 9  - DMAEN  (Abilita tutti i DMA successivi)
                                ; 8  - BPLEN  (Bit plane DMA Enable)
                                ; 7  - COPEN  (Coprocessor DMA Enable)
                                ; 6  - BLTEN  (Blitter DMA enable)
                                ; 5  - SPREN  (Sprite DMA enable)
                                
; 1000011111000000 = 87C0   => Senza sprite ma con blipri a 1
; 1000001111000000 = 83C0   => Senza sprite e con blitpri a 0

    ;move.w  #$83C0,$dff096



    ;move.w	#0,$dff1fc		; Disattiva l'AGA
	;move.w	#$c00,$dff106		; Disattiva l'AGA
	;move.w	#$11,$dff10c		; Disattiva l'AGA


    ; Setto CINQUE bitplane 

    lea     Bplpointers,a0 
    move.l  #Bitplanes,d0

    moveq   #5-1,d1
PuntaBP:
    move.w  d0,6(a0)
    swap    d0 
    move.w  d0,2(a0) 
    swap    d0
    addq.l  #8,a0
    addi.l  #40,d0
    dbra    d1,PuntaBP



    ; Setto lo spritepointer (dff120) nello stesso modo fatto per i bitplane

    lea     SpritePointers,a0
    move.l  #ShipBulletSprite,d0

    move.w  d0,6(a0)
    swap    d0
    move.w  d0,2(a0)
    swap    d0


    ; Setto la copperlist, ovviamente DOPO aver disabilitato gli interrupt se no il SO potrebbe interferire

    move.l  #Copper,$dff080     ; http://amiga-dev.wikidot.com/hardware:cop1lch  (Copper pointer register) E' un long word move perché il registro è una long word

; TODO: Eventualmente fare una copia generale, ma è solo un dettaglio

     lea     Background,a0
     lea     Bitplanes,a1
     move.w  #5,d0
     move.w  #26,d1
     bsr.w   SimpleBlit

     bsr.w   CopiaSfondo



mainloop:




; Gestione mostri

;    bsr.w   DrawMonstersBackground
    bsr.w   UpdateMonstersPositions
    bsr.w   DrawMonsters

; Gestione Ship, questo può stare ovunque.

    bsr.w   CleanShipBackground
    bsr.w   UpdateShipPosition
    bsr.w   DrawShip

; Gestione Fuoco Ship
    bsr.w   CheckFire

    tst.w   ShipBulletActive
    beq.s   .nobulletactive

    bsr.w   UpdateShipBulletPosition

    bsr.w   CheckCollisions

; Devo ripetere per forza il controllo per il frame immediatamente successivo
; a una collisione
    tst.w   ShipBulletActive
    beq.s   .nobulletactive
    bsr.w   DrawShipBullet

    
.nobulletactive


    

;    bsr.w   WaitVBL
    bsr.w   wframe


    btst    #6,$bfe001
    bne     mainloop

    rts
; ===== FINE CODICE 


; *************** INIZIO ROUTINE UTILITY

CheckCollisions:

    lea     Monsters,a0

.loopmonsters
    move.w  (a0)+,d0            ; x in d0

    cmpi.w  #$ffff,d0      ; E' fine lista?
    beq.s   .fineloopmonsters

    move.w  (a0)+,d1            ; y in d0
    add.w   #2,a0               ; Salto il tipo di mostro che non mi interessa
    move.w  (a0)+,d2            ; vita del mostro in d2

; E' un mostro ancora in vita?
    tst.w   d2
    beq.s   .loopmonsters       ; Se no passo al prossimo

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

    bsr.w   DisableShipBullet

; Settare il mostro in stato esplosivo

    bra.s   .fineloopmonsters
.nocoll
    bra.s   .loopmonsters


.fineloopmonsters
    rts


DrawMonsters:
    
    lea     Monsters,a4
 
.loopmonsters:
    move.w  (a4)+,d0
    cmpi.w  #$ffff,d0      ; E' fine lista?
    beq.s   .fineloopmonsters

    move.w  (a4)+,d1        ; Copio posizione Y
    move.w  (a4)+,d5        ; Copio il tipo
    move.w  (a4)+,d6        ; Vivo o morto?

    cmp.w   #1,d6           ; E' vivo?
    bne.s   .nonvivo

    cmp.w   #0,d5           ; E' il mostro verde?
    bne.s   .nogreen
    lea     GreenMonster,a0
    lea     GreenMonsterMask,a1
    bra.s   .found
.nogreen
    cmp.w   #1,d5           ; E' il mostro rosso?
    bne.s   .nored
    lea     RedMonster,a0
    lea     RedMonsterMask,a1
    bra.s   .found
.nored
    lea     YellowMonster,a0        ; Allora è quello giallo
    lea     YellowMonsterMask,a1

.found
    
    move.w  #2,d2           ; Dimensione in word
    move.w  #16*5,d3          ; Altezza
;    move.w  #5,d4           ; Numero bitplane

    lea     Bitplanes,a2
    lea     Background,a3

    bsr.w   BlitBob

.nonvivo

    bra.s   .loopmonsters

.fineloopmonsters:
    rts

; -----------------------------------------

UpdateMonstersPositions:
    
    move.w  MonstersDirection,d0
    move.w  MonstersDirectionCounter,d1

    cmpi.w  #32,d1
    bne.s   .noninverte

    tst.w   d0
    bne.s   .destra             ; Se non è 0 allora andavano a destra 
    move.w  #1,MonstersDirection ; Se è 0 andavano a sinistra e li faccio andare a destra
    bra.s   .sinistra
.destra
    move.w  #0,MonstersDirection ; Li faccio andare a sinistra
.sinistra
    move.w  #0,MonstersDirectionCounter  ; In ogni caso azzero il contatore
    bsr.w   MoveAllMonstersDown         ; E li sposto tutti in basso
    rts

.noninverte
    bsr.w   MoveAllMonstersHorizontally
    add.w   #1,MonstersDirectionCounter
    rts

; ---------------------------------------

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

; -------------------------

MoveAllMonstersDown:

    lea     Monsters,a0
.loopmonsters_d
    move.w  (a0)+,d1
    cmpi.w  #$ffff,d1      ; E' fine lista?
    beq.s   .fineloopmonsters_d

    add.w   #1,(a0)
    add.w   #6,a0

    bra.s   .loopmonsters_d

.fineloopmonsters_d
    rts

; --------

DrawShip:

    lea     Ship,a0
    lea     ShipMask,a1
    lea     Bitplanes,a2

    move.w  ShipBobX,d0
    move.w  #ShipY,d1
    move.w  #2,d2
    move.w  #16*5,d3
    

    bsr.w   BlitBob

    rts

; --------

CleanShipBackground:
    move.w  ShipBobX,d0

    lsr.l   #4,d0           ; Divido per 16 prendendo le word di cui spostarmi a destra
    lsl.l   #1,d0           ; Rimoltiplico per due per ottenere i byte

    lea     Bitplanes+(ShipY*5*40),a0

    add.l   d0,a0

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

    move.w  #36,$dff066         ; Modulo canale Destinazione D

    move.w  #((16*5)*64)+2,$dff058      ; BLTSIZE
    rts

UpdateShipPosition:

    ; JOY1DAT http://amiga-dev.wikidot.com/hardware:joy0dat
    move.w  $dff00c,d3
    btst.l  #1,d3       ; Bit 1 (destra) è azzerato?
    beq.s   .nodestra   ; Se si salto lo spostamento a destra

; Spostamento a destra
    cmpi.w  #320-16,ShipBobX
    beq.s   .exit
    addq.w  #ShipSpeed,ShipBobX
    rts
.nodestra
    btst.l  #9,d3       ; Il bit 9 (sinistra) è azzerato?
    beq.s   .exit       ; Se si esce

    tst.w   ShipBobX
    beq.s   .exit

    subq.w  #ShipSpeed,ShipBobX
.exit
    rts

; ---------------------------

CheckFire:
    tst.w   ShipBulletActive
    bne.s   .exit_cf
    btst    #7,$bfe001
    bne.s   .exit_cf

    move.w  #1,ShipBulletActive
    move.w  ShipBobX,ShipBulletX
    move.w  #ShipY-9,ShipBulletY

.exit_cf
    rts

; ------------------

UpdateShipBulletPosition:
    move.w  ShipBulletY,d0
    cmpi.w  #ShipBulletTopYMargin,d0
    bne.s   .nonmargine

    bsr.w   DisableShipBullet

.nonmargine
    subi.w  #ShipBulletSpeed,ShipBulletY
    rts

; ------------------

DisableShipBullet:

    move.w  #0,ShipBulletActive
    move.w  #0,ShipBulletY
    move.w  #0,ShipBulletX

    move.w  #0,ShipBulletSprite

    rts
; ------------------

DrawShipBullet:
    lea     ShipBulletSprite,a1
    move.w  ShipBulletY,d0
    move.w  ShipBulletX,d1
    move.w  #7,d2

    bsr.w   PointSprite

    rts

; ---------------------------

;
; Routine per il waitraster 
; Aspetta la rasterline in d0.w , modifica d0-d2/a0

WaitRaster:
    movem.l d0-d2/a0,-(SP)

    move.l  #$1ff00,d2
    lsl.l   #8,d0
    and.l   d2,d0
    lea     $dff004,a0
.wr:
    move.l  (a0),d1
    and.l   d2,d1
    cmp.l   d1,d0
    bne.s   .wr

    movem.l (SP)+,d0-d2/a0
    rts


; a0    Indirizzo Bob
; a1    Indirizzo Maschera
; a2    Indirizzo bitplane (interleaved)
; a3    Background

; d0    Posizione X
; d1    Posizione Y
; d2    Larghezza in word
; d3    Altezza in word totali

BlitBob:
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
;    mulu.w  d4,d1               ; Per il numero dei bitplane
    add.l   d0,d1               ; Gli aggiungo i byte di scostamento a destra della posizione X
    add.l   d1,a2               ; Offset con l'inizio dei bitplane
    add.l   d1,a3               ; In destinazione e background

    move.l  a3,$dff048          ; Setto lo sfondo su BLTCPTH
    move.l  a2,$dff054          ; Setto la destinazione su BLTDPTH

    ; Calcolo moduli

;    lsl.l   #1,d2               ; Moltiplico d2 per due, per ottenere i byte della larghezza
;    move.l  #40,d6              ; 40 in d6 (numero di byte per ogni riga)
;    sub.l   d2,d6               ; 40 - d2*2 e trovo il modulo

    move.w  #0,$dff064          ; Modulo zero per la sorgente BLTAMOD
    move.w  #0,$dff062          ; Modulo zero per la sorgente maschera BLTBMOD
    move.w  #36,$dff060          ; Modulo per il canale C con lo sfondo BLTCMOD
    move.w  #36,$dff066          ; Setto il modulo per il canale D di destiazione BLTDMOD

    ; Bltsize: dimensione y * 64 + dim x

;    mulu.w  d4,d3               ; Altezza * numero di bitplane
;    lsl.l   #6,d3               ; Sposto l'altezza nei 10 bit alti di BLTSIZE

;    lsr.l   #1,d2               ; Riporto la larghezza in word

;    add.w   d2,d3
    lsl.w   #6,d3
    add.w  d2,d3

    move.w  d3,$dff058                   ; Setto le dimensioni e lancio la blittata

    movem.l (SP)+,d5-d7/a3

    rts

; -------------------------------------
; primo test con tutti i calcoli, anche se semplificati

DrawMonstersBackground:

    lea     GreenRow,a0
    bsr.w   .drawbackground

    lea     RedRow,a0
    bsr.w   .drawbackground

    lea     YellowRow,a0
    bsr.w   .drawbackground
    
    rts

.drawbackground
    tst     $dff002
.waitblit
    btst    #14-8,$dff002
    bne.s   .waitblit           ; Aspetto il blitter che finisce

    clr.l   d0
    clr.l   d1

    
    lea     Background,a1
    lea     Bitplanes,a2
    move.w  (a0)+,d0        ; x
    move.w  (a0),d1         ; y

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
; -------------------------------------

; TODO: ATTENZIONE QUA!
; Sto copiando bellamente un'intera schermata a ogni frame, non so se il
; blitter ce la fa al 50mo di secondo. Eventualmente inventarsi qualcos'altro.
CopiaSfondo:

    movem.l d0/d1/a0/a1,-(SP)

    lea     Background+(26*40*5),a0
    lea     Bitplanes+(26*40*5),a1
    move.w  #200,d0
    move.w  #5,d1
    bsr.w   SimpleBlit
    
    lea     Background+(226*40*5),a0
    lea     Bitplanes+(226*40*5),a1
    move.w  #30,d0
    move.w  #5,d1
    bsr.w   SimpleBlit

    movem.l (SP)+,d0/d1/a0/a1
    rts

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



; Versione infamia
WaitVBL:
.wat
	cmpi.b	#$FF,$dff006
	bne.s	.wat
.wat2:
	cmpi.b	#$38,$dff006
	bne.s	.wat2	
	rts	


wframe:
	btst #0,$dff005
	bne.b wframe
	cmp.b #$c1,$dff006      ; Spostato da 2a a c1 per dare aria al blitter
	bne.b wframe
wframe2:
	cmp.b #$c1,$dff006
	beq.b wframe2
    rts
; *************** FINE ROUTINE UTILITY





gfxname:
    dc.b    "graphics.library",0


    SECTION tut,DATA_C

    EVEN

Copper:
    dc.w    $1fc,0          ; slow fetch mode, per compatibilità con AGA
 
  ; DMA Display Window: Valori classici di Amiga, non overscan
   ; Ogni valore esadecimale corrisponde a 2 pixel, quindi ogni volta per esempio che riduciamo la finestra di 16 pixel dobbiamo togliere 8
   ; da $92 e $94

    dc.w $8e,$2c81      ; Display window start (top left) http://amiga-dev.wikidot.com/hardware:diwstrt
    dc.w $90,$2cc1      ; Display window stop (bottom right)
    dc.w $92,$38        ; Display data fetch start http://amiga-dev.wikidot.com/hardware:ddfstrt
    dc.w $94,$d0        ; Display data fetch stop

bplane_modulo = (320/16)*4

    dc.w    $108,40*4          ; BPLxMOD: http://amiga-dev.wikidot.com/hardware:bplxmod  - Modulo interleaved
    dc.w    $10a,40*4


; Palette
	dc.w	$0180,$0001,$0182,$0035,$0184,$0046,$0186,$0467
	dc.w	$0188,$0068,$018a,$0578,$018c,$018a,$018e,$01ac
	dc.w	$0190,$02df,$0192,$068a,$0194,$06ac,$0196,$05ef
	dc.w	$0198,$08ab,$019a,$09bc,$019c,$0ade,$019e,$0dff
	dc.w	$01a0,$0d00,$01a2,$0800,$01a4,$0e80,$01a6,$0ff0
	dc.w	$01a8,$0990,$01aa,$0444,$01ac,$0555,$01ae,$0666
	dc.w	$01b0,$0777,$01b2,$0888,$01b4,$0090,$01b6,$00d0
	dc.w	$01b8,$0333,$01ba,$0777,$01bc,$0bbb,$01be,$0fff

; dff120    SPR0PTH     Sprite 0 pointer, 5 bit alti
; dff122    SPR0PTL     Sprite 0 pointer, 15 bit bassi
; e così via per gli altri 7: http://amiga-dev.wikidot.com/hardware:sprxpth

SpritePointers:
	dc.w $120,0
	dc.w $122,0

	dc.w $124,0
	dc.w $126,0
	dc.w $128,0
	dc.w $12a,0
	dc.w $12c,0
	dc.w $12e,0
	dc.w $130,0
	dc.w $132,0
	dc.w $134,0
	dc.w $136,0
	dc.w $138,0
	dc.w $13a,0
	dc.w $13c,0
	dc.w $13e,0



Bplpointers:
	dc.w	$e0,0,$e2,0
	dc.w	$e4,0,$e6,0
	dc.w	$e8,0,$ea,0
	dc.w	$ec,0,$ee,0
	dc.w	$f0,0,$f2,0

   dc.w    $100,$5200      ; move 5200 in dff100 (BPLCON0), le move instructions partono da 080, mettere dopo il setting del bitplane, ma a me non ha mai dato problemi
                            ; 0010100100000000


    ; Per finire la copperlist inseriamo un comando wait (fffe), se vogliamo aspettare la horizonal scanline AC e la posizione orizzontale 07
    ; dc.w    $ac07,$fffe     ; $fffe è la "maschera" che maschera l'ultimo bit meno significativo.
    ; per dire al copper che non ci sono più istruzioni in questo frame gli diamo una wait position impossibile
    dc.w    $ffff,$fffe




    EVEN
Bitplanes:

    dcb.b   (40*256)*5,0

Background:
    incbin "Back.raw"


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
Ship:
    incbin "Ship.raw"
ShipMask:
    incbin "ShipMask.raw"
ShipBullet:
    incbin "ShipBullet.raw"
ShipBulletMask:
    incbin "ShipBulletMask.raw"


BobPosX:
    dc.w    0

; Posizionamento dei singoli mostri
; Struttura dati:
; X.w       Posizione X
; Y.b       Posizione Y
; Tipo.b    Tipo di mostro
; Vivo.b    Vivo = 1, Morto = 0

; Tipi:
; 0 = Green monster
; 1 = Red monster
; 2 = Yellow monster
; Se X.w è FFFF => Fine lista.
Monsters:

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

; 1 : destra
; 0 : sinistra
MonstersDirection:
    dc.w    1

MonstersDirectionCounter:
    dc.w    0

; Struttura dati per il salvataggio del fondale prima del movimento dei bob
; Nel caso dei mostri, siccome sono tutti sulla stessa altezza, semplifico facendo
; salvataggio delle tre strisce

; Offset.l      : offset della word in alto a sinistra del blocco
; Width.w       : larghezza in word
; Height.w      : altezza (numero righe)
; Bitplane.w    : numero bitplane
BackupBkgMonsters:
    dc.l    0
    dc.w    0
    dc.w    0
    dc.w    0

BackupBkgShipBullet:
    dc.l    0
    dc.w    0
    dc.w    0
    dc.w    0

ShipBobX:
    dc.w    120

ShipBulletActive:
    dc.w    0
ShipBulletX:
    dc.w    0
ShipBulletY:
    dc.w    0

ShipBulletSprite:
	dc.w $0,$0	;Vstart.b,Hstart/2.b,Vstop.b,%A0000SEH
	dc.w	$300c,$300c
	dc.w	$781e,$781e
	dc.w	$4812,$781e
	dc.w	$0000,$781e
	dc.w	$0000,$300c
	dc.w	$300c,$0000
	dc.w	$300c,$0000

	dc.w 0,0

NullSpr:
	dc.w $2a20,$2b00
	dc.w 0,0
	dc.w 0,0
