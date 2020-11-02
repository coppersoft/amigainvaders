; d0:	srcX
; d1:	srcY

; d2:	dstX
; d3:	dstY

; d4:	src box width/2  + dst box width/2
; d5:	src box height/w + dst box height/2


; Prova routine di boundary collision



	move.w	#100,d0		; srcX
	move.w	#100,d1		; srxY

	move.w	#118,d2		; dstX
	move.w	#110,d3		; dstY

	move.w	#(16/2)+(16/2),d4
	move.w	#(16/2)+(16/2),d5



Collision:
	sub.w	d2,d0
	bpl.s	.nondx
	neg.w	d0
.nondx
	cmp.w	d4,d0
	bhi.s	.nohit

	sub.w	d3,d1
	bpl.s	.nondy
	neg.w	d1

.nondy
	cmp.w	d5,d1
	bpl.s	.nohit
; Collisione!!!
	move.w	#100,d7
	
.nohit

	rts



