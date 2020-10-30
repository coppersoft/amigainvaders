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

    ;move.w  #$87e0,$dff096          ; Come sopra ma con gli sprite attivi

    move.w  #$87e0,$dff096      ; DMACON (write) 1000011111100000
                                ; 15 - Set Clear bit a 1 => i bit a 1 settano
                                ; 10 - BlitPRI a 1
                                ; 9  - DMAEN  (Abilita tutti i DMA successivi)
                                ; 8  - BPLEN  (Bit plane DMA Enable)
                                ; 7  - COPEN  (Coprocessor DMA Enable)
                                ; 6  - BLTEN  (Blitter DMA enable)
                                ; 5  - SPREN  (Sprite DMA enable)
                                


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

;    lea     SpritePointers,a0
;    move.l  #Spr0,d0

;    move.w  d0,6(a0)
;    swap    d0
;    move.w  d0,2(a0)
;    swap    d0


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



    bsr.w   MoveTestBob

    move.w  #1,d0
    
    bsr.w   UpdateMonstersPositions

    bsr.w   DrawMonsters

    bsr.w   wframe



    btst    #6,$bfe001
    bne     mainloop

    rts
; ===== FINE CODICE 


; *************** INIZIO ROUTINE UTILITY

MoveTestBob:

    lea     GreenMonster,a0
    lea     GreenMonsterMask,a1

    lea     Bitplanes,a2


    clr.l   d0
    move.w  BobPosX,d0      
    move.w  #40,d1
    move.w  #2,d2
    move.w  #16,d3
    move.w  #5,d4

    bsr.w   BlitBob

    btst    #10,$dff016 ; test RIGHT mouse click
    bne     nonsposta

    addi.w  #1,BobPosX
	

nonsposta:
    rts

DrawMonsters:
    
    lea     Monsters,a3
    clr.l   d0
    clr.l   d1
    clr.l   d2
    clr.l   d3
    clr.l   d4
    clr.l   d5
    clr.l   d6


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
    move.w  #16,d3          ; Altezza
    move.w  #5,d4           ; Numero bitplane

    lea     Bitplanes,a2

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
    addi.w  #20,d0

    move.w  d0,$dff058  ; Dimensioni e blittata
    rts



wframe:
	btst #0,$dff005
	bne.b wframe
	cmp.b #$2a,$dff006
	bne.b wframe
wframe2:
	cmp.b #$2a,$dff006
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



Spr0:
	dc.w $2c80,$3c00	;Vstart.b,Hstart/2.b,Vstop.b,%A0000SEH
	dc.w %0000011111000000,%0000000000000000
	dc.w %0001111111110000,%0000000000000000
	dc.w %0011111111111000,%0000000000000000
	dc.w %0111111111111100,%0000000000000000
	dc.w %0110011111001100,%0001100000110000
	dc.w %1110011111001110,%0001100000110000
	dc.w %1111111111111110,%0000000000000000
	dc.w %1111111111111110,%0000000000000000
	dc.w %1111111111111110,%0010000000001000
	dc.w %1111111111111110,%0001100000110000
	dc.w %0111111111111100,%0000011111000000
	dc.w %0111111111111100,%0000000000000000
	dc.w %0011111111111000,%0000000000000000
	dc.w %0001111111110000,%0000000000000000
	dc.w %0000011111000000,%0000000000000000
	dc.w %0000000000000000,%0000000000000000
	dc.w 0,0

NullSpr:
	dc.w $2a20,$2b00
	dc.w 0,0
	dc.w 0,0
