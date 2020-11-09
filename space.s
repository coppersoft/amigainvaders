;    Amiga Invaders

;    a space invaders game for Commodore Amiga, written in 68000 assembly
;    for the Retro Programmers Inside (RPI) gamedev competition.

;    Copyright (C) 2020 - Lorenzo Di Gaetano <lorenzodigaetano@yahoo.it>

;    This program is free software: you can redistribute it and/or modify
;    it under the terms of the GNU General Public License as published by
;    the Free Software Foundation, either version 3 of the License, or
;    (at your option) any later version.

;    This program is distributed in the hope that it will be useful,
;    but WITHOUT ANY WARRANTY; without even the implied warranty of
;    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;    GNU General Public License for more details.

;    You should have received a copy of the GNU General Public License
;    along with this program.  If not, see <https://www.gnu.org/licenses/>.



ShipY = 239
ShipSpeed = 2
ShipBulletTopYMargin = 28
ShipBulletSpeed = 1
NumberOfMonsters = 21

    SECTION MyDemo,CODE_C

    include "functions/init.s"


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

    lea     ShipBulletSpritePointer,a0
    move.l  #ShipBulletSprite,d0

    move.w  d0,6(a0)
    swap    d0
    move.w  d0,2(a0)

    lea     EnemyBullet1SpritePointer,a0
    move.l  #EnemyBulletSprite1,d0

    move.w  d0,6(a0)
    swap    d0
    move.w  d0,2(a0)

    lea     EnemyBullet2SpritePointer,a0
    move.l  #EnemyBulletSprite2,d0

    move.w  d0,6(a0)
    swap    d0
    move.w  d0,2(a0)


    ; Setto la copperlist, ovviamente DOPO aver disabilitato gli interrupt se no il SO potrebbe interferire

    move.l  #Copper,$dff080     ; http://amiga-dev.wikidot.com/hardware:cop1lch  (Copper pointer register) E' un long word move perché il registro è una long word

; TODO: Eventualmente fare una copia generale, ma è solo un dettaglio

     lea     Background,a0
     lea     Bitplanes,a1
     move.w  #5,d0
     move.w  #26,d1
     bsr.w   SimpleBlit

     bsr.w   CopiaSfondo

; GAME LOOP

mainloop:
; Gestione mostri


;    bsr.w   UpdateMonstersPositions
;   

; Gestione Ship, questo può stare ovunque.

    bsr.w   CleanShipBackground
    bsr.w   UpdateShipPosition
    bsr.w   DrawShip

; Gestione fuoco nemico
    bsr.w   EnemyShoot1_Fire
    bsr.w   UpdateEnemyShoot1

    bsr.w   EnemyShoot2_Fire
    bsr.w   UpdateEnemyShoot2

; Gestione Fuoco Ship
    bsr.w   CheckFire

    tst.w   ShipBulletActive
    beq.s   .nobulletactive

    bsr.w   UpdateShipBulletPosition

    ; Checkcollisions cancella il mostro dallo schermo e inserisce
    ; una nuova esplosione nella lista
    bsr.w   CheckCollisions

 
; Devo ripetere per forza il controllo per il frame immediatamente successivo
; a una collisione
    tst.w   ShipBulletActive
    beq.s   .nobulletactive
    bsr.w   DrawShipBullet

    
.nobulletactive

    ; Alla fine visualizzo le eventuali esplosioni in corso

    bsr.w   CleanExplosionsBackground

    bsr.w   DrawMonsters
    
    bsr.w   DrawExplosions


;    bsr.w   WaitVBL
    bsr.w   wframe


    btst    #6,$bfe001
    bne     mainloop

    rts
; ===== FINE LOOP PRINCIPALE

; Includo funzioni utility per blitter e sprite
    include "functions/blitter.s"
    include "functions/sprite.s"

; *************** INIZIO ROUTINE UTILITY


; Gestione Fuoco nemico 1

EnemyShoot1_Fire:
    tst.w   EnemyBullet1Active
    beq.s   .fireshoot1
    rts
.fireshoot1



    ; Trovo il primo mostro ancora vivo, partendo dall'ultimo che ha sparato
.loopmonsters

    cmp.w   #NumberOfMonsters,EnemyBullet1Shooter
    bne.s   .nonazzera
    move.w  #0,EnemyBullet1Shooter
.nonazzera

    move.w  EnemyBullet1Shooter,d0
    lea     Monsters,a0     ; Prendo l'elenco dei mostri

    lsl.l   #3,d0           ; Ogni mostro occupa 8 byte, quindi moltiplico per 8
    add.l   d0,a0
   
    move.w  (a0)+,EnemyBullet1X
    move.w  (a0)+,EnemyBullet1Y
    add.w   #2,a0
    move.w  (a0)+,d1        ; Vita del mostro in d1

    tst.w   d1
    bne.s   .attivafuocomostro
    add.w   #1,EnemyBullet1Shooter
    bra.s   .loopmonsters

.attivafuocomostro
    move.w  #1,EnemyBullet1Active

    rts

UpdateEnemyShoot1:
    tst.w   EnemyBullet1Active
    bne.s   .update
    rts
.update
    add.w   #1,EnemyBullet1Y

    move.w  EnemyBullet1X,d0
    move.w  ShipBobX,d1
    cmp.w   d0,d1
    beq.s   .nonmuovihoriz

    cmp.w   d0,d1
    bhi.s   .spostadx                            ; Se ShipBobX > EnemyBullet1X
    bra.s   .sx
.spostadx
    add.w   #1,EnemyBullet1X
    bra.s   .nosx
.sx
    sub.w   #1,EnemyBullet1X
.nosx

.nonmuovihoriz


    lea     EnemyBulletSprite1,a1
    move.w  EnemyBullet1Y,d0
    move.w  EnemyBullet1X,d1

    add.w  #5,d1
    add.w  #16,d0

    move.w  #5,d2

    bsr.w   PointSprite

    cmpi.w  #255,EnemyBullet1Y
    bne.s   .nondisattiva

    move.w  #0,EnemyBullet1Active
    add.w   #1,EnemyBullet1Shooter

.nondisattiva
    rts

; -----------

; Gestione Fuoco nemico 2

EnemyShoot2_Fire:
    tst.w   EnemyBullet2Active
    beq.s   .fireshoot2
    rts
.fireshoot2



    ; Trovo il primo mostro ancora vivo, partendo dall'ultimo che ha sparato
.loopmonsters

    cmp.w   #NumberOfMonsters,EnemyBullet2Shooter
    bne.s   .nonazzera
    move.w  #0,EnemyBullet2Shooter
.nonazzera

    move.w  EnemyBullet2Shooter,d0
    lea     Monsters,a0     ; Prendo l'elenco dei mostri

    lsl.l   #3,d0           ; Ogni mostro occupa 8 byte, quindi moltiplico per 8
    add.l   d0,a0
   
    move.w  (a0)+,EnemyBullet2X
    move.w  (a0)+,EnemyBullet2Y
    add.w   #2,a0
    move.w  (a0)+,d1        ; Vita del mostro in d1

    tst.w   d1
    bne.s   .attivafuocomostro
    add.w   #1,EnemyBullet2Shooter
    bra.s   .loopmonsters

.attivafuocomostro
    move.w  #1,EnemyBullet2Active

    rts

UpdateEnemyShoot2:
    tst.w   EnemyBullet2Active
    bne.s   .update
    rts
.update
    add.w   #1,EnemyBullet2Y

    move.w  EnemyBullet2X,d0
    move.w  ShipBobX,d1
    cmp.w   d0,d1
    beq.s   .nonmuovihoriz

    cmp.w   d0,d1
    bhi.s   .spostadx                            ; Se ShipBobX > EnemyBullet1X
    bra.s   .sx
.spostadx
    add.w   #1,EnemyBullet2X
    bra.s   .nosx
.sx
    sub.w   #1,EnemyBullet2X
.nosx

.nonmuovihoriz


    lea     EnemyBulletSprite2,a1
    move.w  EnemyBullet2Y,d0
    move.w  EnemyBullet2X,d1

    add.w  #5,d1
    add.w  #16,d0

    move.w  #5,d2

    bsr.w   PointSprite

    cmpi.w  #255,EnemyBullet2Y
    bne.s   .nondisattiva

    move.w  #0,EnemyBullet2Active
    add.w   #1,EnemyBullet2Shooter 
.nondisattiva
    rts





; --------------

; d0 x
; d1 y
AddExplosion:
    lea     ExplosionsList,a0
    move.w  #0,d3
.looplist
    move.w  (a0),d2             ; Cerco la fine della lista
    cmpi.w  #$ffff,d2
    beq.s   .trovatafinelista
    add.w   #2,a0               ; Proseguo
    add.w   #2,d3               ; E aggiorno il contatore di scostamento
    bra.s   .looplist
.trovatafinelista



    move.w  d0,(a0)+            ; Sostituisco il segnale di fine lista con la x
    move.w  d1,(a0)+            ; y
    move.w  #0,(a0)+            ; Primo fotogramma
    move.w  #$ffff,(a0)         ; Nuovo fine lista
    rts

; ------------------

CleanExplosionsBackground:
    lea     ExplosionsList,a0

.explosionsloop
    move.w  (a0)+,d0        ; X in d0
    cmpi.w  #$ffff,d0       ; Se è fine lista
    beq.s   .endloop

    move.w  (a0)+,d1

    bsr.w   CleanHitMonster
    add.w   #2,a0
    bra.s   .explosionsloop

.endloop
    rts

; ------------------

DrawExplosions:
    lea     ExplosionsList,a4

.explosionsloop

    move.w  (a4)+,d0        ; X in d0
    cmpi.w  #$ffff,d0       ; Se è fine lista
    beq.s   .endloop        ; esco

    move.w  (a4)+,d1        ; y in d1
    move.w  (a4),d4        ; Offset lista fotogrammi per questa esplosione in d4

    lea     ExplosionFrames,a0
    lea     ExplosionFramesMasks,a1
    lea     Bitplanes,a2
    lea     Bitplanes,a3

    lea     ExplosionFramesList,a5
    lsl.l   d4              ; Moltiplico per 2
    add.l   d4,a5           ; Punto il fotogramma nella lista dei frame
    move.w  (a5),d4         ; Prendo il numero del fotogramma della grafica

; TODO qui controllare che non sia $ffff

    cmpi.w  #$ffff,d4       ; Sono alla fine della lista dei fotogrammi?
    bne.s   .nofinefotogrammi
    sub.l   #4,a4
    move.w  #$ffff,(a4)     ; Fine esplosione

    ; E' sicuramente l'ultima della LIFO, quindi mi posso fermare qui
    bra.s   .endloop

.nofinefotogrammi
    add.w   #1,(a4)
;

    mulu.w  #(4*16*5),d4      ; Offset con la grafica bitmap

    add.l   d4,a0           ; E vado a prendere la bitmap del fotogramma
    add.l   d4,a1

    move.w  #16*5,d3

    bsr.w   BlitBob16

    add.w  #2,a4           ; Prossima eventuale esplosione
    bra.s   .explosionsloop
    
.endloop
    rts

; ------------

CheckCollisions:

    lea     Monsters,a0

.loopmonsters
    move.w  (a0)+,d0            ; x in d0

    move.w  d0,d6               ; Mi salvo la x in d6

    cmpi.w  #$ffff,d0      ; E' fine lista?
    beq.s   .fineloopmonsters

    move.w  (a0)+,d1            ; y in d1

    move.w  d1,d7               ; Mi salvo la y in d7

    add.w   #2,a0               ; Salto il tipo di mostro che non mi interessa
    move.w  (a0)+,d2            ; vita del mostro in d2

; E' un mostro ancora in vita?
    tst.w   d2
    beq.s   .loopmonsters       ; Se no passo al prossimo

; E' in vita, prendo la posizione del proiettile
    move.w  ShipBulletX,d2      ; xp in d2
    move.w  ShipBulletY,d3      ; yp in d3

    move.w	#(16/2)+(4/2),d4   ; larghezza boundaries mostro e proiettile
	move.w	#(16/2)+(6/2),d5   ; altezza boundaries mostro e proiettile

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

    sub.w   #2,a0       ; vado a recuperare la vita del mostro colpito
    move.w  #0,(a0)     ; Setto il mostro in stato "morto"
    add.w   #2,a0       ; rimetto com'era prima per continuare il loop in modo pulito

    ; Pulisco lo sfondo del mostro
    move.w  d6,d0
    move.w  d7,d1
    bsr.w   CleanHitMonster

    move.w  d6,d0
    move.w  d7,d1
    bsr.w   AddExplosion

    bra.s   .fineloopmonsters
.nocoll
    bra.s   .loopmonsters


.fineloopmonsters
    rts

; --------------

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

    bsr.w   BlitBob16

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
    

    bsr.w   BlitBob16

    rts

; --------



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
	cmp.b #$fe,$dff006      ; Spostato da 2a a c1 per dare aria al blitter
	bne.b wframe
wframe2:
	cmp.b #$fe,$dff006
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
	dc.w	$01b0,$0777,$01b2,$0070,$01b4,$0090,$01b6,$00d0
	dc.w	$01b8,$0333,$01ba,$0777,$01bc,$0bbb,$01be,$0fff

; dff120    SPR0PTH     Sprite 0 pointer, 5 bit alti
; dff122    SPR0PTL     Sprite 0 pointer, 15 bit bassi
; e così via per gli altri 7: http://amiga-dev.wikidot.com/hardware:sprxpth

; Sprite 0 proiettile astronave
; Sprite 5 e 6 proiettili nemici
ShipBulletSpritePointer:
	dc.w $120,0
	dc.w $122,0

	dc.w $124,0
	dc.w $126,0
	dc.w $128,0
	dc.w $12a,0
	dc.w $12c,0
	dc.w $12e,0
EnemyBullet1SpritePointer:
	dc.w $130,0
	dc.w $132,0
EnemyBullet2SpritePointer:
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
    incbin "gfx/Back.raw"


GreenMonster:
    incbin "gfx/GreenMon.raw"
GreenMonsterMask:
    incbin "gfx/GreenMonMask.raw"
RedMonster:
    incbin "gfx/RedMon.raw"
RedMonsterMask:
    incbin "gfx/RedMonMask.raw"
YellowMonster:
    incbin "gfx/YellowMon.raw"
YellowMonsterMask:
    incbin "gfx/YellowMonMask.raw"
Ship:
    incbin "gfx/Ship.raw"
ShipMask:
    incbin "gfx/ShipMask.raw"
ShipBullet:
    incbin "gfx/ShipBullet.raw"
ShipBulletMask:
    incbin "gfx/ShipBulletMask.raw"


BobPosX:
    dc.w    0

; Posizionamento dei singoli mostri
; Struttura dati:
; X.w       Posizione X
; Y.w       Posizione Y
; Tipo.w    Tipo di mostro
; Vivo.w    Vivo = 1, Morto = 0

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

    dc.w    $ffff

; 1 : destra
; 0 : sinistra
MonstersDirection:
    dc.w    1

MonstersDirectionCounter:
    dc.w    0



;BackupBkgShipBullet:
    dc.l    0
    dc.w    0
    dc.w    0
    dc.w    0

ShipBobX:
    dc.w    120

; Bullets

ShipBulletActive:
    dc.w    0
ShipBulletX:
    dc.w    0
ShipBulletY:
    dc.w    0

EnemyBullet1Active:
    dc.w    0
EnemyBullet1X:
    dc.w    0
EnemyBullet1Y:
    dc.w    0
EnemyBullet1Shooter:
    dc.w    0

EnemyBullet2Active:
    dc.w    0
EnemyBullet2X:
    dc.w    0
EnemyBullet2Y:
    dc.w    0
EnemyBullet2Shooter:
    dc.w    15

; Struttura esplosione
; x.w
; y.w
; frame.w
; $ffff fine lista
ExplosionsList:
    dc.w    $ffff
    dcb.w   3*10,0  ; 10 dovrebbero bastare...  

ExplosionFrames:
    incbin  "gfx/Exp1.raw"
    incbin  "gfx/Exp2.raw"
    incbin  "gfx/Exp3.raw"
    incbin  "gfx/Exp4.raw"
    incbin  "gfx/Exp5.raw"
    incbin  "gfx/Exp6.raw"
    incbin  "gfx/Exp7.raw"
    incbin  "gfx/Exp8.raw"
    incbin  "gfx/Exp9.raw"

ExplosionFramesMasks:
    incbin  "gfx/Exp1Mask.raw"
    incbin  "gfx/Exp2Mask.raw"
    incbin  "gfx/Exp3Mask.raw"
    incbin  "gfx/Exp4Mask.raw"
    incbin  "gfx/Exp5Mask.raw"
    incbin  "gfx/Exp6Mask.raw"
    incbin  "gfx/Exp7Mask.raw"
    incbin  "gfx/Exp8Mask.raw"
    incbin  "gfx/Exp9.raw"

ExplosionFramesList:
    dc.w    0,0,0,0,0,1,1,1,1,1,2,2,2,2,2,3,3,3,3,3,4,4,4,4,4,5,5,5,5,5,6,6,6,6,6,7,7,7,7,7,8,$ffff




ShipBulletSprite:
	dc.w    $0,$0	;Vstart.b,Hstart/2.b,Vstop.b,%A0000SEH
	dc.w	$0180,$0180
	dc.w	$03c0,$03c0
	dc.w	$0240,$03c0
	dc.w	$0000,$03c0
	dc.w	$0000,$0180
	dc.w	$0180,$0000
	dc.w	$0180,$0000
	dc.w 0,0

EnemyBulletSprite1:
	dc.w    $0,$0	;Vstart.b,Hstart/2.b,Vstop.b,%A0000SEH
	dc.w	$0000,$7000
	dc.w	$6800,$f000
	dc.w	$4800,$f000
	dc.w	$1800,$f000
	dc.w	$7000,$0000
    dc.w    0,0

EnemyBulletSprite2:
	dc.w    $0,$0	;Vstart.b,Hstart/2.b,Vstop.b,%A0000SEH
	dc.w	$0000,$7000
	dc.w	$6800,$f000
	dc.w	$4800,$f000
	dc.w	$1800,$f000
	dc.w	$7000,$0000
    dc.w    0,0


NullSpr:
	dc.w $2a20,$2b00
	dc.w 0,0
	dc.w 0,0
