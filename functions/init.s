; Codice di partenza

; ====== BLOCCO DEL SISTEMA OPERATIVO E DEGLI INTERRUPT

init:
    ; Dobbiamo salvare la copperlist del sistema operativo, ma lo facciamo con una chiamata alla graphics.library
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

; Per utilizzare gli interrupt per la musica devo ottenere il Vector Base Register
; Nel 68000 è sempre zero, ma nei successivi (dal 68010 in poi) può non esserlo

    btst.b  #0,$129(a6)         ; Controllo se sono su 68010 o superiore
    beq.s   foundvbr            ; E' un 68000, non mi serve trovare il VBR
    lea     FindVBR,a5          ; Altrimenti metto in a5 l'indirizzo del codice da chiamare in modalità supervisor
    jsr     -$1e(a6)            ; LvoSupervisor

    bra.s   foundvbr

FindVBR:
    movem.l a0-a1,-(SP)
    dc.l    $4e7a9801           ; movec vbr,a1 (68010+ messo in hex per evitare di settare il compilatore a 68000+)
    lea     BaseVBR,a0
    move.l  a1,(a0)             ; Salvo il VBR in BaseVBR
    movem.l (SP)+,a0-a1
    rte     

foundvbr:
    move.l  BaseVBR,a0
    move.l  $6c(a0),OldInt6c    ; Mi salvo l'indirizzo del vecchio interrupt 6c, quello che uso per la musica



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

    or      #$c000,d5           ; Setto a 1 il bit più significativo, quello di controllo
                                ; è 1100000000000000, devo riattivare il bit 14 (master interrupt) mettendogli 1 (bit 15 set/clr)
                                ; http://amiga-dev.wikidot.com/hardware:intenar
    move    d5,$dff09a          ; Ripristino l'INTENA come era prima di disattivare tutti gli interrupt

; interrupt

    move.l  BaseVBR,a0
    move.l  OldInt6c,$6c(a0)    ; Ripristino il vecchio interrupt


    moveq   #0,d0               ; No error code al sistema operativo

    rts

; ===== FINE RIPRISTINO SISTEMA OPERATIVO E USCITA

BaseVBR:
    dc.l    0
OldInt6c:
    dc.l    0