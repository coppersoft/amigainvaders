Testbackground:

    lea     GreenRow,a0
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

    tst     $dff002
.waitblit
    btst    #14-8,$dff002
    bne.s   .waitblit           ; Aspetto il blitter che finisce

    ; 0 = shift nullo
    ; 9 = 1001: abilito solo i canali A e D
    ; f0 = minterm, copia semplice
    ;move.l  #$09f00000,$dff040  ; Dico al blitter che operazione effettuare, BLTCON

    ;move.l #$ffffffff,$dff044   ; maschera, BLTAFWM e BLTALWM

    move.l  a1,$dff050    ; Setto la sorgente su BLTAPTH
    move.l  a2,$dff054    ; Setto la destinazione su BLTDPTH

    move.w  #(40-(9*4)),d2    ; Modulo per la sorgente BLTAMOD
    move.w  #(40-(9*4)),d3    ; Setto il modulo per il canale D di destiazione BLTDMOD

    move.w  #((16*5)*64)+18,d4

    rts


    GreenRow:
    dc.w    8
    dc.w    40
    dc.w    0
    dc.w    1

    Bitplanes:

    dcb.b   (40*256)*5,0

Background:
    incbin "Back.raw"
