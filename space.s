;    Amiga Invaders

;    a space invaders game for Commodore Amiga OCS/ECS, written in 68000 assembly
;    for the Retro Programmers Inside (RPI) gamedev competition.

;    AMIGA WILL NEVER DIE!!!!!

;    Copyright (C) 2020 - Lorenzo Di Gaetano <lorenzodigaetano@yahoo.it>

;    Uses P61 mod play routine by Jarno Paananen

;    Compile with
;    vasmm68k_mot -Fhunkexe -kick1hunks space.s

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

; Costanti

ShipY = 239
ShipStartX = 120
ShipBulletTopYMargin = 28
NumberOfMonsters = 27

ExplosionFrameNumber = 43
ShipInvincibilityFrameNumber = 100

MegaUfoYPosition = 30
MegaUfoDelay = 4*50



    SECTION AmigaInvaders_Code,CODE_C

    include "music/P61.conf"
    include "functions/init.s"


; ===== INIZIO CODICE 

START:

; E' meglio aspettare l'end of frame prima di smaneggiare con questi registri

    move.w  #$138,d0
    bsr.w   WaitRaster
    
    move.w  #$7fff,$dff09a           ; Disabilito tutti i bit in INTENA (interrupt enable)

;   Tolto perché ora mi servono gli interrupt!
;    move.w  #$7fff,$dff09c          ; (Buona pratica:) Disabilito tutti i bit in INTREQ
;    move.w  #$7fff,$dff09c          ; (Buona pratica:) Disabilito tutti i bit in INTREQ, faccio due volte per renderlo compatibile con A4000 che ha un bug

; Per disabilitare tutti i DMA completamente, facciamo qualcosa di simile a quanto fatto qui sopra con gli interrupt

    move.w  #$7fff,$dff096          ; Disabilito tutti i bit in DMACON

; Abilito copper, bitplanes, sprite ecc...

; DMACON dff096 DMA Control write (clear or set) http://amiga-dev.wikidot.com/hardware:dmaconr

    move.w  #$87e0,$dff096      ; DMACON (write) 1000011111100000
                                ; 15 - Set Clear bit a 1 => i bit a 1 settano
                                ; 10 - BlitPRI a 1
                                ; 9  - DMAEN  (Abilita tutti i DMA successivi)
                                ; 8  - BPLEN  (Bit plane DMA Enable)
                                ; 7  - COPEN  (Coprocessor DMA Enable)
                                ; 6  - BLTEN  (Blitter DMA enable)
                                ; 5  - SPREN  (Sprite DMA enable)

; Inizializzo la routine P61 per la musica

	movem.l	d0-d7/a0-a6,-(SP)
	moveq	#0,d0		; Timer Detection: Autodetect
	lea	    Music,a0	; Indirizzo del modulo in a0
	lea	    $dff000,a6	; Ricordiamoci il $dff000 in a6!
	sub.l	a1,a1		; I samples non sono a parte, mettiamo zero
	sub.l	a2,a2		; no samples -> modulo non compattato
	bsr.w	P61_Init
	movem.l	(SP)+,d0-d7/a0-a6

    lea     $dff000,a5
    move.w	#0,$1fc(a5)		    ; Disattiva l'AGA
	move.w	#$c00,$106(a5)		; Disattiva l'AGA
	move.w	#$11,$10c(a5)		; Disattiva l'AGA
    move.w	#%1110000000100000,$09a(a5)	; Setto INTENA, interrupt enable bits.
                                        ; 15: Bit set/clr, come per DMACON
                                        ; 14: Master interrupt
                                        ; 13: External interrupt
                                        ; 5:  VERTB: abilito l'interrupt all'inizio del vblank, per il player musicale

    move.l	BaseVBR,a4          ; BaseVBR recuperato, se necessario, in init.s
	move.l	#INTERRUPT,$6c(a4)	; Punto il mio interrupt


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

    lea     MegaUfoLeftSpritePointer,a0
    move.l  #MegaUfoLeftSprite,d0

    move.w  d0,6(a0)
    swap    d0
    move.w  d0,2(a0)

    lea     MegaUfoRightSpritePointer,a0
    move.l  #MegaUfoRightSprite,d0

    move.w  d0,6(a0)
    swap    d0
    move.w  d0,2(a0)

    ; Setto la copperlist

    move.l  #Copper,$dff080     ; http://amiga-dev.wikidot.com/hardware:cop1lch  (Copper pointer register) E' un long word move perché il registro è una long word

; PRESENTAZIONE INIZIALE

    lea     Presentazione,a0
    move.l  draw_buffer,a1
    move.w  #200,d0
    move.w  #5,d1
    bsr.w   SimpleBlit

    lea     Presentazione+(200*44*5),a0
    move.l  draw_buffer,a1
    add.l   #200*44*5,a1
    move.w  #55,d0
    move.w  #5,d1
    bsr.w   SimpleBlit

    bsr.w   SwitchBuffers

    move.l  #0,d0
.fadein_pres:
    lea     PaletteRaw,a0
    lea     Palette+2,a1
    moveq   #32-1,d1
    addi.b  #1,d0
    bsr.w   Fade
    bsr.w   wframe
    bsr.w   wframe
    cmpi.b  #16,d0
    bne.s   .fadein_pres
    
.pr_loop:
    btst    #7,$bfe001
    bne.s   .pr_loop

	moveq	#16,d0
.fadeout_pres:
	lea	    PaletteRaw,a0
	lea	    Palette+2,a1
	moveq	#32-1,d1
	subi.b	#1,d0
	bsr.w	Fade
    bsr.w   wframe
    bsr.w   wframe
	tst.b	d0
	bne.s	.fadeout_pres


; FINE PRESENTAZIONE INIZIALE

RestartGame:
    move.w  #3,Lifes
    move.w  #1,GameLevel
    move.w  #0,Score

InitLevel:

    move.w  #1,MonstersDirection
    move.w  #0,MonstersDirectionCounter

    move.w  #0,ShipBulletActive
    move.w  #0,ShipBulletX
    move.w  #0,ShipBulletY

    move.w  #ShipStartX,ShipBobX

    move.w  #0,EnemyBullet1Active
    move.w  #0,EnemyBullet2Active
    move.w  #0,EnemyBullet1X
    move.w  #0,EnemyBullet1Y
    move.w  #0,EnemyBullet2X
    move.w  #0,EnemyBullet2Y

    move.w  #0,EnemyBullet1Shooter
    move.w  #10,EnemyBullet2Shooter     

    move.w  #NumberOfMonsters,MonstersLeft

    move.w  #0,ShipStatus
    move.w  #0,MegaUfoTimer
    move.w  #0,MegaUfoMoving
    move.w  #-32,MegaUfoXposition
    
    bsr.w   PointMegaUfo

; Stabilisco il livello di difficoltà

    cmpi.w  #1,GameLevel
    bne.s   .non1

    move.w  #2,ShipSpeed
    move.w  #2,ShipBulletSpeed
    move.w  #0,FollowingBullets
    bra.w   .iniziogioco

.non1:
    cmpi.w  #2,GameLevel
    bne.s   .non2

    move.w  #2,ShipSpeed
    move.w  #2,ShipBulletSpeed
    move.w  #1,FollowingBullets
    bra.w   .iniziogioco

.non2:
    cmpi.w  #3,GameLevel
    bne.s   .giocofinito

    move.w  #2,ShipSpeed
    move.w  #1,ShipBulletSpeed
    move.w  #1,FollowingBullets
    bra.w   .iniziogioco

.giocofinito

.waitforexplosionend
    bsr.w   CleanExplosionsBackground
    bsr.w   DrawExplosions

    bsr.w   CleanShipBackground
    bsr.w   DrawShip

    bsr.w   SwitchBuffers

    bsr.w   wframe

    lea     ExplosionsList,a0
    cmpi.w  #$ffff,(a0)
    bne.s   .waitforexplosionend

    lea     MissioneCompletata,a0
    lea     MissioneCompletataMask,a1
    move.l  draw_buffer,a2

    move.w  #48,d0
    move.w  #112,d1
 
    move.w  #14,d2
    move.w  #31,d3
    move.w  #5,d4

    bsr.w   BlitBob

    bsr.w   SwitchBuffers

.go_loop:
    btst    #7,$bfe001
    bne.s   .go_loop

    bra.w   RestartGame


.iniziogioco

    bsr.w   CopiaSfondo
    bsr.w   ShowLifes

    bsr.w   DrawScore

; Copio le posizioni iniziali dei mostri
    move.w  #(4*NumberOfMonsters)-1,d0                    ; 4 word per 27 mostri

    lea     MonstersStartPositions,a0
    lea     Monsters,a1

.copyloop
    move.w  (a0)+,(a1)+
    dbra    d0,.copyloop

; GAME LOOP

    move.l  #0,d0

mainloop:

; Fade in ingame
    cmpi.w  #16,FadeInFrame
    beq.s   .nofadein

    addi.w  #1,FadeInFrame
    move.w  FadeInFrame,d0
    lea     PaletteRaw,a0
    lea     Palette+2,a1
    moveq   #32-1,d1
    
    bsr.w   Fade

.nofadein:


; Gestione mostri

    bsr.w   UpdateMonstersPositions
    bsr.w   UpdateMegaUfo

; Gestione Ship, questo può stare ovunque.

    cmpi.w  #1,ShipStatus               ; Se sta esplodendo
    beq.s   .nonaggiornaposizioneship

    bsr.w   CleanShipBackground     ; OK
    
    bsr.w   UpdateShipPosition
    bsr.w   DrawShip                ; OK

.nonaggiornaposizioneship

; Gestione fuoco nemico
    bsr.w   EnemyShoot1_Fire
    bsr.w   UpdateEnemyShoot1

    bsr.w   EnemyShoot2_Fire
    bsr.w   UpdateEnemyShoot2

; CheckcollisionsWithMonsters cancella il mostro dallo schermo e inserisce
; una nuova esplosione nella lista
    bsr.w   CheckCollisionsWithMonsters

    bsr.w   CheckCollisionsWithMegaUfo

; Controllo collisioni proiettili nemici con l'astronave
; Se è in stato esplosione o invincibile non controlla
    cmpi.w  #1,ShipStatus
    beq.s   .nocheckcollship

    cmpi.w  #2,ShipStatus
    beq.s   .nocheckcollship

    bsr.w   CheckCollisionsWithShip

.nocheckcollship


; Gestione Fuoco Ship
    bsr.w   CheckFire

    tst.w   ShipBulletActive
    beq.s   .nobulletactive

    bsr.w   UpdateShipBulletPosition

; Devo ripetere per forza il controllo per il frame immediatamente successivo
; a una collisione
    tst.w   ShipBulletActive
    beq.s   .nobulletactive
    bsr.w   DrawShipBullet

    
.nobulletactive

    ; Alla fine visualizzo le eventuali esplosioni in corso

    bsr.w   CleanExplosionsBackground   ; chiama cleanhitmonster che è ok
    bsr.w   DrawMonsters                ; OK
    bsr.w   DrawExplosions              ; OK

    bsr.w   SwitchBuffers
    bsr.w   wframe

; Fase controllo stati dell'astronave

    cmpi.w  #1,ShipStatus
    bne.s   .nonesplode
    addq.w  #1,ShipExplosionFrameCounter

    cmpi.w  #ExplosionFrameNumber,ShipExplosionFrameCounter
    bne.s   .esplosionenonfinita
    move.w  #0,ShipExplosionFrameCounter

; Fase controllo se ho finito le vite

    tst.w   Lifes
    bne.s   .nonfinite
    bsr.w   GameOverLoop
    bra.w   RestartGame

.nonfinite:
    move.w  #2,ShipStatus

.esplosionenonfinita
.nonesplode

    cmpi.w  #2,ShipStatus
    bne.s   .noninvincibile

    addq.w  #1,ShipInvincibilityFrameCounter

    cmpi.w  #ShipInvincibilityFrameNumber,ShipInvincibilityFrameCounter
    bne.s   .invincibilitanonfinita

    move.w  #0,ShipInvincibilityFrameCounter
    move.w  #0,ShipStatus
    lea     Ship,a0
    move.l  a0,ShipFrame

.invincibilitanonfinita
.noninvincibile

; Fase controllo se almeno uno dei mostri è arrivato in fondo

    bsr.w   CheckMonstersOnBottom
    tst.w   d2
    beq.s   .nonarrivati

    bsr.w   GameOverLoop
    bra.w   RestartGame

.nonarrivati

; Fase controllo se ho ucciso tutti i mostri

    tst.w   MonstersLeft
    bne.s   .nonfinito
    addq.w  #1,GameLevel
    bsr.w   LevelClearedLoop
    bra.w   InitLevel
.nonfinito

    btst    #6,$bfe001
    bne     mainloop

    bsr.w   P61_End

    rts
; ===== FINE LOOP PRINCIPALE

; Loop Livello Completato
LevelClearedLoop:

    cmpi.w  #4,GameLevel
    beq.s   .fine_lcloop            ; Se ho finito il gioco salto la visualizzazione

.waitforexplosionend
    bsr.w   CleanExplosionsBackground
    bsr.w   DrawExplosions

    bsr.w   CleanShipBackground
    bsr.w   DrawShip

    bsr.w   SwitchBuffers

    bsr.w   wframe

    lea     ExplosionsList,a0
    cmpi.w  #$ffff,(a0)
    bne.s   .waitforexplosionend

    lea     LivelloCompletato,a0
    lea     LivelloCompletatoMask,a1
    move.l  draw_buffer,a2

    move.w  #84,d0
    move.w  #112,d1
    move.w  #10,d2
    move.w  #26,d3
    move.w  #5,d4

    bsr.w   BlitBob

    bsr.w   SwitchBuffers
.mc_loop
    btst    #7,$bfe001
    bne.s   .mc_loop

.fine_lcloop:

    rts


GameOverLoop:
    lea     GameOver,a0
    lea     GameOverMask,a1
    move.l  view_buffer,a2

    move.w  #96,d0
    move.w  #98,d1
 
    move.w  #7,d2
    move.w  #61,d3
    move.w  #5,d4

    bsr.w   BlitBob

;    bsr.w   SwitchBuffers

.go_loop:
    btst    #7,$bfe001
    bne.s   .go_loop

    rts


; Includo funzioni utility per blitter, sprite, collisioni, conversioni e player musicale
    include "functions/blitter.s"
    include "functions/sprite.s"
    include "functions/utils.s"
    include "music/P6112-Play.s"

; *************** INIZIO ROUTINE UTILITY

CheckCollisionsWithShip:

    move.w  ShipBobX,d0
    move.w  #ShipY-5,d1
    move.w  EnemyBullet1X,d2
    move.w  EnemyBullet1Y,d3
    move.w  #(16/2)+(4/2),d4
    move.w  #(16/2)+(4/2),d5
    
    bsr.w   BoundaryCheck

    tst.w   d0
    bne.s   .collide

; Controllo anche il secondo, eventualmente salto se il livello
; non prevede un secondo bullet

    move.w  ShipBobX,d0
    move.w  #ShipY-5,d1
    move.w  EnemyBullet2X,d2
    move.w  EnemyBullet2Y,d3
    move.w  #(16/2)+(4/2),d4
    move.w  #(16/2)+(4/2),d5

    bsr.w   BoundaryCheck

    tst.w   d0
    beq.s   .noncollide

.collide
    bsr.w   CleanShipBackground
    move.w  ShipBobX,d0
    move.w  #ShipY,d1
    bsr.w   AddExplosion
    move.w  #1,ShipStatus
    sub.w   #1,Lifes
    bsr.w   ShowLifes

.noncollide
    rts



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
    
    addq.w  #1,EnemyBullet1Y

    tst.w   FollowingBullets
    beq.s   .nonmuovihoriz

    move.w  EnemyBullet1X,d0
    move.w  ShipBobX,d1
    cmp.w   d0,d1
    beq.s   .nonmuovihoriz

    cmp.w   d0,d1
    bhi.s   .spostadx                            ; Se ShipBobX > EnemyBullet1X
    bra.s   .sx
.spostadx
    addq.w  #1,EnemyBullet1X
    bra.s   .nosx
.sx
    subq.w  #1,EnemyBullet1X
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
    blt.s   .nondisattiva

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
    addq.w  #1,EnemyBullet2Y

    tst.w   FollowingBullets
    beq.s   .nonmuovihoriz

    move.w  EnemyBullet2X,d0
    move.w  ShipBobX,d1
    cmp.w   d0,d1
    beq.s   .nonmuovihoriz

    cmp.w   d0,d1
    bhi.s   .spostadx                            ; Se ShipBobX > EnemyBullet1X
    bra.s   .sx
.spostadx
    addq.w  #1,EnemyBullet2X
    bra.s   .nosx
.sx
    subq.w  #1,EnemyBullet2X
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
    blt.s   .nondisattiva

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
    move.w  (a0),d2       ; Cerco la fine della lista
    cmpi.w  #$ffff,d2
    beq.s   .trovatafinelista
    add.w   #2,a0         ; Proseguo
    add.w   #1,d3        ; E aggiorno il contatore di scostamento
    bra.s   .looplist
.trovatafinelista

.shift
    move.w  (a0),6(a0)
    sub.w   #2,a0
    dbra    d3,.shift

    lea	    ExplosionsList,a0
    move.w  d0,(a0)+      ; Sostituisco il segnale di fine lista con la x
    move.w  d1,(a0)+      ; y
    move.w  #0,(a0)+      ; Primo fotogramma
;    move.w  #$ffff,(a0)   ; Nuovo fine lista
    rts

; ------------------

CleanExplosionsBackground:
    lea     ExplosionsList,a0

.explosionsloop
    move.w  (a0)+,d0        ; X in d0
    cmpi.w  #$ffff,d0       ; Se è fine lista
    beq.s   .endloop

    move.w  (a0)+,d1

    bsr.w   CleanBackground
    add.w   #2,a0
    bra.s   .explosionsloop

.endloop
    rts

; ------------------

DrawExplosions:

    movem.l d0-d4/a0-a5,-(SP)

    lea     ExplosionsList,a4

.explosionsloop

    clr.l   d4

    move.w  (a4)+,d0        ; X in d0
    cmpi.w  #$ffff,d0       ; Se è fine lista
    beq.s   .endloop        ; esco

    move.w  (a4)+,d1        ; y in d1
    move.w  (a4),d4        ; Offset lista fotogrammi per questa esplosione in d4

    lea     ExplosionFrames,a0
    lea     ExplosionFramesMasks,a1
    move.l  draw_buffer,a2
    move.l  draw_buffer,a3

    lea     ExplosionFramesList,a5
    lsl.l   d4              ; Moltiplico per 2
    add.l   d4,a5           ; Punto il fotogramma nella lista dei frame
    move.w  (a5),d4         ; Prendo il numero del fotogramma della grafica

    cmpi.w  #$ffff,d4       ; Sono alla fine della lista dei fotogrammi?
    bne.s   .nofinefotogrammi
    sub.l   #4,a4
    move.w  #$ffff,(a4)     ; Fine esplosione

    ; E' sicuramente l'ultima della LIFO, quindi mi posso fermare qui
    bra.s   .endloop

.nofinefotogrammi
    add.w   #1,(a4)
    
    mulu.w  #(4*16*5),d4      ; Offset con la grafica bitmap

    add.l   d4,a0           ; E vado a prendere la bitmap del fotogramma
    add.l   d4,a1

    move.w  #16*5,d3

    bsr.w   BlitBob16

    add.w  #2,a4           ; Prossima eventuale esplosione
    bra.s   .explosionsloop
    
.endloop

    movem.l (SP)+,d0-d4/a0-a5
    rts

; ------------

CheckCollisionsWithMonsters:

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
	move.w	#(10/2)+(2/2),d5   ; altezza boundaries mostro e proiettile

    bsr.w   BoundaryCheck
    tst.w   d0
    beq.s   .nocoll
; Collisione!!!

    bsr.w   DisableShipBullet

    sub.w   #2,a0       ; vado a recuperare la vita del mostro colpito
    move.w  #0,(a0)     ; Setto il mostro in stato "morto"
    add.w   #2,a0       ; rimetto com'era prima per continuare il loop in modo pulito

    ; Pulisco lo sfondo del mostro
    move.w  d6,d0
    move.w  d7,d1
    bsr.w   CleanBackground

    move.w  d6,d0
    move.w  d7,d1
    bsr.w   AddExplosion

    sub.w   #1,MonstersLeft

    add.w   #10,Score
    bsr.w   DrawScore

    bra.s   .fineloopmonsters
.nocoll
    bra.s   .loopmonsters


.fineloopmonsters
    rts

; --------------
CheckCollisionsWithMegaUfo:

    tst.w   MegaUfoMoving
    beq.s   .exit

    move.w  ShipBulletX,d0
    move.w  ShipBulletY,d1
    move.w  MegaUfoXposition,d2
    move.w  #MegaUfoYPosition,d3

    move.w  #(4/2)+(32/2),d4
    move.w  #(4/2)+(10/2),d5

    bsr.w   BoundaryCheck
    tst.w   d0
    beq.s   .exit

    move.w  MegaUfoXposition,d0
    move.w  #MegaUfoYPosition,d1
    bsr.w   AddExplosion

    move.w  MegaUfoXposition,d0
    add.w   #16,d0
    move.w  #MegaUfoYPosition,d1
    bsr.w   AddExplosion

    bsr.w   ResetMegaUfo
    bsr.w   DisableShipBullet
    bsr.w   PointMegaUfo

    add.w   #100,Score
    bsr.w   DrawScore

.exit:
    rts

; -------------

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
    
    move.w  #16*5,d3          ; Altezza

    move.l  draw_buffer,a2
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

    cmpi.w  #2,ShipStatus
    bne.s   .noninvincibile

    lea     Ship,a0
    lea     ShipInv,a1
    lea     ShipFrame,a2
    move.l  (a2),d0
    cmp.l   d0,a0           ; Sto visualizzando il fotogramma normale?
    beq.s   .maschera
    move.l  a0,ShipFrame
    bra.s   .nonmaschera

.maschera
    move.l  a1,ShipFrame    ; Lo sostituisco con la maschera
.nonmaschera


.noninvincibile

    move.l  #0,d0

    move.l  ShipFrame,a0
    lea     ShipMask,a1
    move.l  draw_buffer,a2

    move.w  ShipBobX,d0
    move.w  #ShipY,d1
    move.w  #16*5,d3
    

    bsr.w   BlitBob16

    rts

; --------

UpdateShipPosition:
    move.w  ShipSpeed,d0
    ; JOY1DAT http://amiga-dev.wikidot.com/hardware:joy0dat
    move.w  $dff00c,d3
    btst.l  #1,d3       ; Bit 1 (destra) è azzerato?
    beq.s   .nodestra   ; Se si salto lo spostamento a destra

; Spostamento a destra
    cmpi.w  #320-16,ShipBobX
    beq.s   .exit
    
    add.w   d0,ShipBobX
    rts
.nodestra
    btst.l  #9,d3       ; Il bit 9 (sinistra) è azzerato?
    beq.s   .exit       ; Se si esce

    tst.w   ShipBobX
    beq.s   .exit

    sub.w  d0,ShipBobX
.exit
    rts

; ---------------------------

CheckFire:
    tst.w   ShipBulletActive
    bne.s   .exit_cf
    btst    #7,$bfe001
    bne.s   .exit_cf

    move.w  #1,ShipBulletActive
    move.w  ShipBobX,d0
    addq.w  #6,d0
    move.w  d0,ShipBulletX
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
    move.w  ShipBulletSpeed,d0
    sub.w   d0,ShipBulletY
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

; Routine per la gestione del megaufo
UpdateMegaUfo:
    tst.w   MegaUfoMoving               ; Se si sta muovendo, continuo a muoverlo
    bne.s   .ismoving

    addq.w  #1,MegaUfoTimer             ; Altrimento aumento il timer
    cmpi.w  #MegaUfoDelay,MegaUfoTimer  ; Se è il momento che si muova...
    bne.s   .exit
    move.w  #1,MegaUfoMoving            ; Lo setto
.ismoving:
    addq.w  #2,MegaUfoXposition

    cmpi.w  #320,MegaUfoXposition       ; E' arrivato al margine destro?
    bne.s   .update                     ; Se no non resetta

    bsr.w   ResetMegaUfo

.update:
    bsr.w   PointMegaUfo

.exit
    rts

ResetMegaUfo:
    move.w  #0,MegaUfoMoving
    move.w  #-32,MegaUfoXposition
    move.w  #0,MegaUfoTimer
    rts

PointMegaUfo:
    lea     MegaUfoLeftSprite,a1
    move.w  #MegaUfoYPosition,d0
    move.w  MegaUfoXposition,d1
    move.w  #10,d2
    bsr.w   PointSprite

    lea     MegaUfoRightSprite,a1
    move.w  #MegaUfoYPosition,d0
    move.w  MegaUfoXposition,d1
    add.w   #16,d1
    move.w  #10,d2
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

wframe:
	btst #0,$dff005
	bne.b wframe
	cmp.b #$2a,$dff006      ; Spostato da 2a a c1 per dare aria al blitter
	bne.b wframe
wframe2:
	cmp.b #$2a,$dff006
	beq.b wframe2
    rts

INTERRUPT:
	btst.b	#5,$dff01f  ; Si deve testare se l'interrupt è arrivato davvero da un VERTB
                        ; Perché potrebbe essere lanciato anche da altri eventi
                        ; Controllo quindi il bit 5 di INTREQR, se è a 0 salto tutto
	beq.s	Novertb     
	
	movem.l	d0-d7/a0-a6,-(sp)

	lea	    $dff000,a6
	bsr.w	P61_Music		

	movem.l	(sp)+,d0-d7/a0-a6

Novertb:
	move.w	#%1110000,$dff09c
	rte

; *************** FINE ROUTINE UTILITY

gfxname:
    dc.b    "graphics.library",0


    SECTION AmigaInvaders_data,DATA_C

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

    dc.w    $108,4+(44*4)          ; BPLxMOD: http://amiga-dev.wikidot.com/hardware:bplxmod  - Modulo interleaved
    dc.w    $10a,4+(44*4)


; Palette
Palette:
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
; Sprite 4 e 5 proiettili nemici
ShipBulletSpritePointer:
	dc.w $120,0     ;0
	dc.w $122,0

	dc.w $124,0     ;1
	dc.w $126,0
	dc.w $128,0     ;2
	dc.w $12a,0
	dc.w $12c,0     ;3
	dc.w $12e,0
EnemyBullet1SpritePointer:
	dc.w $130,0     ;4
	dc.w $132,0
EnemyBullet2SpritePointer:
	dc.w $134,0     ;5
	dc.w $136,0
MegaUfoLeftSpritePointer:
	dc.w $138,0     ;6
	dc.w $13a,0
MegaUfoRightSpritePointer:
	dc.w $13c,0     ;7
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


PaletteRaw:
    dc.w	$0001,$0035,$0046,$0467
	dc.w	$0068,$0578,$018a,$01ac
	dc.w	$02df,$068a,$06ac,$05ef
	dc.w	$08ab,$09bc,$0ade,$0dff
	dc.w	$0d00,$0800,$0e80,$0ff0
	dc.w	$0990,$0444,$0555,$0666
	dc.w	$0777,$0070,$0090,$00d0
	dc.w	$0333,$0777,$0bbb,$0fff

FadeInFrame:
    dc.w    0

Bitplanes1:
    dcb.b   (44*256)*5,0
Bitplanes2:
    dcb.b   (44*256)*5,0

view_buffer:
	dc.l	Bitplanes1	; buffer visualizzato
draw_buffer:
	dc.l	Bitplanes2	; buffer di disegno

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
ShipInv:
    incbin "gfx/ShipInv.raw"
Life:
    incbin "gfx/Life.raw"
Digits:
    incbin "gfx/Digits.raw"

ShipBullet:
    incbin "gfx/ShipBullet.raw"
ShipBulletMask:
    incbin "gfx/ShipBulletMask.raw"

; Messaggi

Presentazione:
    incbin "gfx/Presentazione.raw"

LivelloCompletato:
    incbin "gfx/LivComp.raw"
LivelloCompletatoMask:
    incbin "gfx/LivCompMask.raw"

MissioneCompletata:
    incbin "gfx/MissComp.raw"
MissioneCompletataMask:
    incbin "gfx/MissCompMask.raw"

GameOver:
    incbin "gfx/GameOver.raw"
GameOverMask:
    incbin "gfx/GameOverMask.raw"

ShipExplosionFrameCounter:
    dc.w    0

ShipInvincibilityFrameCounter:
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
   dcb.w    4*NumberOfMonsters,0

   dc.w    $ffff
MonstersStartPositions:
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

GameLevel:
    dc.w    1

; 1 : destra
; 0 : sinistra
MonstersDirection:
    dc.w    1

MonstersDirectionCounter:
    dc.w    0

MonstersLeft:
    dc.w    NumberOfMonsters

; MegaUfo
MegaUfoXposition:
    dc.w    -32
MegaUfoTimer:
    dc.w    0
MegaUfoMoving:
    dc.w    0


Score:
    dc.w    0
ScoreStr:
    dcb.b   6,0


ShipBobX:
    dc.w    120

ShipSpeed:
    dc.w    2

; Bullets

ShipBulletActive:
    dc.w    0
ShipBulletX:
    dc.w    0
ShipBulletY:
    dc.w    0
ShipBulletSpeed:
    dc.w    2

; Proiettili nemici

FollowingBullets:
    dc.w    1

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

Music:
    incbin  "music/P61.trackdj"

ExplosionFramesList:
    dc.w    0,0,0,0,0,1,1,1,1,1,2,2,2,2,2,3,3,3,3,3,4,4,4,4,4,5,5,5,5,5,6,6,6,6,6,7,7,7,7,7,8,8,8,$ffff

; 0 = Playing
; 1 = Missione Completata
GameStatus:
    dc.w    0

; 0 = Playing
; 1 = Esplode
; 2 = Invincibile
ShipStatus:
    dc.w    0

ShipFrame:
    dc.l    Ship

Lifes:
    dc.w    3


; SPRITES:

ShipBulletSprite:
	dc.w    $0,$0	;Vstart.b,Hstart/2.b,Vstop.b,%A0000SEH

	dc.w	$6000,$6000
	dc.w	$f000,$f000
	dc.w	$9000,$f000
	dc.w	$0000,$f000
	dc.w	$0000,$6000
	dc.w	$6000,$0000
	dc.w	$6000,$0000

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

MegaUfoLeftSprite:
    dc.w    $0,$0	;Vstart.b,Hstart/2.b,Vstop.b,%A0000SEH
    dc.w	$0000,$00ff
	dc.w	$0000,$07ff
	dc.w	$0000,$1fff
	dc.w	$0444,$3ddd
	dc.w	$0000,$7999
	dc.w	$0000,$ffff
	dc.w	$0000,$ffff
	dc.w	$ffff,$0000
	dc.w	$1f07,$0000
	dc.w	$0e03,$0000
    dc.w    0,0

MegaUfoRightSprite:
    dc.w    $0,$0	;Vstart.b,Hstart/2.b,Vstop.b,%A0000SEH
	dc.w	$0000,$ff00
	dc.w	$0000,$ffe0
	dc.w	$0000,$fff8
	dc.w	$4440,$dddc
	dc.w	$0000,$999e
	dc.w	$0001,$fffe
	dc.w	$0007,$fff8
	dc.w	$ffff,$0000
	dc.w	$e0f8,$0000
	dc.w	$c070,$0000
    dc.w    0,0

NullSpr:
	dc.w $2a20,$2b00
	dc.w 0,0
	dc.w 0,0
