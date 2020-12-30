fadeintes:
	lea	Paltes,a0
	lea	Tespalette+2,a1
	moveq	#16-1,d1
	addi.b	#1,d0
	bsr.w	FadeL
	bsr.w	WaitVBL
	cmpi.b	#16,d0
	bne.s	fadeintes
Attend:
	btst	#6,$bfe001
	bne.s	Attend		

    rts

WaitVBL:
Wat:
	cmpi.b	#$FF,$dff006
	bne.s	wat
Wat2:
	cmpi.b	#$38,$dff006
	bne.s	wat2	
	rts	

FadeL:

	moveq	#0,d2
	moveq	#0,d3

	move.w	(a0),d2
	andi.w	#$000f,d2
	mulu.w	d0,d2
	lsr.w	#4,d2
	andi.w	#$000f,d2
	move.w	d2,d3
	
	move.w	(a0),d2
	andi.w	#$00f0,d2
	mulu.w	d0,d2
	lsr.w	#4,d2
	andi.w	#$00f0,d2
	or.w	d2,d3
	
	move.w	(a0)+,d2
	andi.w	#$0f00,d2
	mulu.w	d0,d2
	lsr.w	#4,d2
	andi.w	#$0f00,d2
	or.w	d2,d3
	
	move.w	d3,(a1)
	addq.w	#4,a1
	dbra	d1,FadeL
	rts

; Palette nuda e cruda
paltes:
	dc.w	$0000,$0102,$0222,$0325
	dc.w	$0555,$0408,$0428,$0659
	dc.w	$076d,$067f,$097d,$0999
	dc.w	$099f,$0bcf,$0dbf,$0cdf

Tespalette:
	dc.w	$0180,$0000,$0182,$0102,$0184,$0222,$0186,$0325
	dc.w	$0188,$0555,$018a,$0408,$018c,$0428,$018e,$0659
	dc.w	$0190,$076d,$0192,$067f,$0194,$097d,$0196,$0999
	dc.w	$0198,$099f,$019a,$0bcf,$019c,$0dbf,$019e,$0cdf