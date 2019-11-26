;x86 asm Tetris
;Microprocessors Project
;--------------------------- 
INCLUDE macros.inc
.MODEL HUGE 
.STACK 64
.DATA
;INSERT DATA HERE
GAMESCRWIDTH        DW  100     ;width of each screen
GAMESCRHEIGHT       DW  160     ;height of each screen


						;Tetris grid is 16x10, so each block is 10x10 pixels
GAMELEFTSCRX        DW  10      ;top left corner X of left screen
GAMELEFTSCRY        DW  15      ;top left corner Y of left screen
GAMERIGHTSCRX       DW  170     ;top left corner X of right screen
GAMERIGHTSCRY       DW  15      ;top left corner Y of right screen

;CONTROL KEYS (scancodes)

;Controls for left screen
leftDownCode			DB	1Fh		;S key
leftLeftCode			DB	1Eh		;A key
leftRightCode			DB	20h		;D key
leftRotCode				DB	11h		;W key
;Controls for right screen
rightDownCode			DB	50h		;downArrow key
rightLeftCode			DB	4Bh 	;leftArrow key
rightRightCode			DB	4Dh		;rightArrow key
rightRotCode			DB	48h 	;upArrow key

;CURRENT PIECE INFO
leftPieceId					DB	?			;contains the ID of the current piece
leftPieceOrientation		DB	?			;contains the current orientation of the piece
leftPieceLocX				DB	?			;the Xcoord of the top left corner
leftPieceLocY				DB	?			;the Ycoord of the top left corner
leftPieceData				DB	16 DUP(?)	;contains the 4x4 matrix of the piece (after orientation)
leftPieceSpeed				DB	1			;contains the falling speed of the left piece

rightPieceId				DB	?			;contains the ID of the current piece
rightPieceOrientation		DB	?			;contains the current orientation of the piece
rightPieceLocX				DB	?			;the Xcoord of the top left corner
rightPieceLocY				DB	?			;the Ycoord of the top left corner
rightPieceData				DB	16 DUP(?)	;contains the 4x4 matrix of the piece (after orientation)
rightPieceSpeed				DB	2			;contains the falling speed of the right piece

tempPieceOffset				DW	?			;contains the address of the current piece


collisionPieceId				DB	?			;contains the ID of the current piece
collisionPieceOrientation		DB	?			;contains the current orientation of the piece
collisionPieceLocX				DB	?			;the Xcoord of the top left corner
collisionPieceLocY				DB	?			;the Ycoord of the top left corner
collisionPieceData				DB	16 DUP(?)	;contains the 4x4 matrix of the piece (after orientation)
collisionPieceSpeed				DB	1			;contains the falling speed of the left piece

;PIECES DATA
firstPiece 					DB 11,11,11,11,0,0,0,0,0,0,0,0,0,0,0,0	;Line shape
secondPiece					DB 1,1,1,0,0,0,1,0,0,0,0,0,0,0,0,0	;J shape
thirdPiece 					DB 6,6,6,0,6,0,0,0,0,0,0,0,0,0,0,0	;L shape 
fourthPiece 				DB 0,14,14,0,0,14,14,0,0,0,0,0,0,0,0,0	;square
fifthPiece					DB 0,0,2,2,0,2,2,0,0,0,0,0,0,0,0,0	;S shape
sixthPiece					DB 5,5,5,5,5,5,0,0,0,0,0,0,0,0,0,0	;T shape
seventhPiece 				DB 4,4,0,0,0,4,4,0,0,0,0,0,0,0,0,0	;Z shape

Seconds						DB 99			;Contains the previous second value

FRAMEWIDTH        equ  10     ;width of each screen
FRAMEHEIGHT       equ  16     ;height of each screen
.CODE
;---------------------------        
MAIN    PROC    FAR
		MOV AX, @DATA   ;SETUP DATA ADDRESS
		MOV DS, AX      ;MOV DATA ADDRESS TO DS

		MOV AH, 0       ;PREPARE GFX MODE
		MOV AL, 13H
		INT 10H         ;ENTER GFX MODE


		;CALL DrawGameScr

		CALL DrawGameScr
		CALL drawPixelsFrame


		MOV SI, 4
		CALL GetTempPiece
		MOV BX, 5
		CALL SetScrPieceData
		MOV SI, 4
		CALL DrawPiece

		MOV SI,0
		CALL GetTempPiece
		MOV BX,4
		CALL SetScrPieceData
		MOV SI,0
		CALL DrawPiece

GAMELP:	
		CALL ParseInput
		CALL PieceGravity
		JMP GAMELP

		MOV AH, 4CH     ;SETUP FOR EXIT
		INT 21H         ;RETURN CONTROL TO DOS
MAIN    ENDP
;---------------------------
;This PROC draws the screens of the two players given the parameters in data segment
;@param     none
;@return    none
DrawGameScr PROC    NEAR
	MOV SI, 0				;0 for left, 4 for right
	MOV AL, 9               ;frame color
	MOV AH, 0CH             ;draw pixel command
DRAWFRAME:
	MOV CX, GAMELEFTSCRX[SI]    ;beginning of top left X
	MOV DX, GAMELEFTSCRY[SI]   	;beginning of top left Y
	ADD DX, GAMESCRHEIGHT	  	;go to bottom
	;INC DX						;draw at bottom + 1 as this is the border
	MOV BX, GAMELEFTSCRX[SI]
	ADD BX, GAMESCRWIDTH    ;set right limit

DRAWHOR:
	INT 10H                 ;draw bottom


	INC CX                  ;inc X
	CMP CX, BX              ;check if column is at limit
	JBE DRAWHOR             ;if yes, exit loop
	
	MOV CX, GAMELEFTSCRX+[SI]    ;beginning of top left X
	DEC CX						 ;go to left - 1
	MOV DX, GAMELEFTSCRY+[SI]    ;beginning of top left Y
	
	MOV BX, GAMELEFTSCRY+[SI]
	ADD BX, GAMESCRHEIGHT   	 ;set bottom limit
	
DRAWVER:
	
	INT 10H                 ;draw left


	ADD CX, GAMESCRWIDTH    ;go to right
	ADD CX, 1				;draw at right + 1
	INT 10H               ;draw right
	SUB CX, GAMESCRWIDTH    ;go back to left	
	SUB CX, 1

	

	INC DX                  ;inc Y
	CMP DX, BX              ;check if row is at limit
	JBE DRAWVER
	ADD SI, 4				;inc SI
	MOV AL, 4				;set color to red for right frame
	CMP SI, 8				;check if loop ran twice
	JNE	DRAWFRAME

	RET
DrawGameScr ENDP
;---------------------------

;---------------------------
;This PROC draws the pixels surrounding the frame of the two players given the parameters in data segment
;@param     none
;@return    none
drawPixelsFrame PROC    NEAR
	MOV SI, 0				;0 for left, 4 for right
	MOV AL, 8               ;frame color
	MOV AH, 0CH             ;draw pixel command

drawPixelsFrameLoop:
	MOV CX, GAMELEFTSCRX[SI]    ;beginning of top left X
	MOV DX, GAMELEFTSCRY[SI]   	;beginning of top left Y
	ADD DX, GAMESCRHEIGHT	  	;go to bottom
	;INC DX						;draw at bottom + 1 as this is the border
	MOV BX, GAMELEFTSCRX[SI]
	ADD BX, GAMESCRWIDTH    ;set right limit
	
	ADD CX,5D
	ADD DX,5D

DRAWPIXELHOR:
	INT 10H                 ;draw bottom
	ADD CX,10D               ;inc X
	CMP CX, BX              ;check if column is at limit
	JBE DRAWPIXELHOR             ;if yes, exit loop
	

	MOV CX, GAMELEFTSCRX+[SI]    ;beginning of top left X
	DEC CX						 ;go to left - 1
	MOV DX, GAMELEFTSCRY+[SI]    ;beginning of top left Y
	
	MOV BX, GAMELEFTSCRY+[SI]
	ADD BX, GAMESCRHEIGHT   	 ;set bottom limit
	
	SUB CX, 5D
	ADD DX, 5D

DRAWPIXELVER:
	INT 10H                 ;draw left

	ADD CX, GAMESCRWIDTH    ;go to right
	ADD CX, 10D				;draw at right + 1
	INT 10H               ;draw right
	SUB CX, GAMESCRWIDTH    ;go back to left	
	SUB CX, 10D

	

	ADD DX,10D                  ;inc Y
	CMP DX, BX              ;check if row is at limit
	JBE DRAWPIXELVER

	ADD SI, 4				;inc SI
	CMP SI, 8				;check if loop ran twice
	JNE	drawPixelsFrameLoop

	RET
drawPixelsFrame ENDP
;---------------------------------
;Takes a block (X,Y) in the 16x10 grid of tetris and returns the color of the block
;@param		CX: X coord,
;		    DX: Y coord, 
;			SI: screen ID: 0 for left, 4 for right
;@return	AL:	color for (X,Y) grid
GetBlockClr	PROC	NEAR							;XXXXXXXXX - NEEDS TESTING
	MOV AX, CX		;top left of (X,Y) block is 10*X + gridTopX
	MOV BL, 10D	
	MUL BL
	ADD AX, 5D
	ADD AX, GAMELEFTSCRX[SI]
	MOV	CX, AX		;CX = 10*Xcoord + gridTopX + 5
	
	MOV AX, DX		;same as above
	MUL BL
	ADD AX, 5D
	ADD AX, GAMELEFTSCRY[SI]
	MOV DX, AX
	
	
	MOV AH, 0DH
	MOV BH, 0
	INT 10H
	RET
GetBlockClr	ENDP
;---------------------------
;Takes a block (X,Y) in the 16x10 grid of tetris and colors the block with a given color
;@param		CX:	X coord,
;			DX: Y coord,
;			SI: screen ID: 0 for left, 4 for right
;			AL: color for (X,Y) grid
;@return	none
DrawBlockClr	PROC	NEAR
	PUSHA
	MOV DI, AX		;push color to DI
					;go to top left of block
	MOV	AX, CX
	MOV BL, 10D
	MUL BL
	ADD AX, GAMELEFTSCRX[SI]
	MOV CX, AX		;CX = 10*Xcoord + gridTopX
	
	MOV AX, DX
	MUL BL
	ADD AX, GAMELEFTSCRY[SI]
	MOV DX, AX		;DX = 10*Ycoord + gridTopY
	
	MOV AX, DI		;pop color to AX
	
	MOV DI, CX		;DI = limit of CX
	ADD DI, 10		;DI = CX + 10 (LIMIT OF CX)
	MOV BX, DX		;BX = limit of DX
	ADD	BX, 10		;BX = DX + 10 (LIMIT OF DX)

	MOV AH, 0CH
LOOPX:
	MOV DX, BX		;Reset DX to original Y
	SUB DX, 10
LOOPY:
	INT 10H			;draw pixel at (CX,DX)
	INC DX			;go to next pixel Y
	CMP DX, BX		
	JNZ LOOPY
	INC CX
	CMP CX, DI
	JNZ LOOPX
	
	POPA
	RET
DrawBlockClr	ENDP
;---------------------------
;This procedure sets the piece data for left or right screen according to tempPieceOffset
;@param			BX: Piece ID			
;@return		none
SetScrPieceData	PROC	NEAR
		MOV DI,	tempPieceOffset
		MOV SI, 0d			;initialize counter	
		MOV [DI], BX		;move id of selected piece to selectedScreenPiece
		MOV AX, 0
		MOV [DI+1], AX		;set orientation to 0
		MOV [DI+3], AX		;set pieceY to 0
		MOV AX, 5			;set pieceX to 5
		MOV [DI+2], AX
		
		ADD DI, 4d			;jump to piece data
		MOV AX, BX
		MOV BX, 16d
		MUL BX
		MOV BX, AX
SETSCRPIECELOP:	
		MOV CL, firstPiece[BX][SI]
		MOV [DI], CL
		INC DI
		INC SI
		CMP SI, 16d
		JNZ SETSCRPIECELOP
		RET
SetScrPieceData	ENDP
;---------------------------
;This procedure copies the piece address into tempPiece according to SI
;@param			SI: screenId: 0 for left, 4 for right
;@return		none 
GetTempPiece	PROC	NEAR
		PUSH SI
		CMP SI, 0					;If the screen is left
		JNZ	RIGHT
		LEA SI, leftPieceId			;copy the leftPieceOffset to SI
		MOV tempPieceOffset, SI		;load the leftPieceOffset to tempPieceOffset
		JMP EXT
RIGHT:										;else if the screen is right
		LEA SI, rightPieceId		;copy the rightPieceOffset to SI
		MOV tempPieceOffset, SI		;load the rightPieceOffset to tempPieceOffset
EXT:	POP SI
		RET
GetTempPiece	ENDP
;---------------------------
;This procedure clears the current temp piece (used in changing direction or rotation)	;NEEDS TESTING
;@param			SI: screenId: 0 for left, 4 for right
;@return		none
DeletePiece		PROC	NEAR
		PUSHA
		MOV BX, tempPieceOffset
		MOV DI, BX						;Load the piece 4x4 string address in pieceData
		ADD DI,	4						;Go to the string data to put in DI
		MOV CX, 0D						;iterate over the 16 cells of the piece
		;if the piece has color !black, draw it with black
		;cell location is:
		;cell_x = orig_x + id%4
		;cell_y = orig_y + id/4
LOPX:			
		MOV DL, [DI]					;copy the byte of color of current cell into DL
		CMP DL, 0D						;check if color of current piece block is black
		JZ 	ISBLACK
		
		PUSH CX
		
		MOV AX, CX
		MOV CL, 4D
		DIV CL						;AH = id%4, AL = id/4
		MOV CX, 0
		MOV DX, 0
		MOV CL, [BX+2]				;load selected piece X into CL
		MOV DL, [BX+3]				;load selected piece Y into DL
		ADD CL, AH					;CX = orig_x + id%4
		ADD DL, AL					;DX = orig_y + id/4
		
		MOV AL, 0

		CALL DrawBlockClr
		
		POP  CX
ISBLACK:		
		INC CX
		INC DI
		CMP CX, 16D
		JNZ LOPX
		POPA
		RET
DeletePiece		ENDP
;---------------------------
;This procedure draws the piece stored in temp piece
;in it's corresponding Data,(X,Y)
;@param			SI: screenId: 0 for left, 4 for right
;@return		none
DrawPiece		PROC	NEAR
		PUSHA
		MOV BX, tempPieceOffset
		MOV DI, BX						;Load the piece 4x4 string address in pieceData
		ADD DI,	4						;Go to the string data to put in DI
		MOV CX, 0D						;iterate over the 16 cells of the piece
		;if the piece has color !black, draw it with it's color
		;cell location is:
		;cell_x = orig_x + id%4
		;cell_y = orig_y + id/4
DRAWPIECELOPX:			
		MOV DL, [DI]					;copy the byte of color of current cell into DL
		CMP DL, 0D						;check if color of current piece block is black
		JZ	 DRAWPIECEISBLACK
		
		PUSH CX
		
		MOV AX, CX
		MOV CL, 4D
		DIV CL						;AH = id%4, AL = id/4
		MOV CX, 0
		MOV DX, 0
		MOV CL, [BX+2]				;load selected piece X into CL
		MOV DL, [BX+3]				;load selected piece Y into DL
		ADD CL, AH					;CX = orig_x + id%4
		ADD DL, AL					;DX = orig_y + id/4
		
		MOV AL, [DI]

		CALL DrawBlockClr
		
		POP  CX
DRAWPIECEISBLACK:		
		INC DI
		INC CX
		CMP CX, 16D
		JNZ DRAWPIECELOPX


		POPA
		RET
DrawPiece		ENDP
;---------------------------
;This procedure takes the direction to move the piece in and re-draws it in the new location	;NOT FINISHED
;@param			
;				BX: direction{0:down, 1:left, 2:right}
;				SI: screenId: 0 for left, 4 for right
;@return		none
MovePiece		PROC	NEAR
		PUSHA
		PUSH BX

		;PUT TEMP PIECE IN MEMORY
		CALL GetTempPiece

		CALL DeletePiece

		;INSERT COLLISION DETECTION HERE
		CALL setCollisionPiece		;Set the offset of the collision piece from temp piece

		CMP BX, 0D					;check for direction of movement
		JZ DOWNDTEMP
		CMP BX, 1D
		JZ LEFTDTEMP
		CMP BX, 2D
		JZ RIGHTDTEMP
DOWNDTEMP:									;move collision piece downward
		MOV BX, offset collisionPieceId
		INC BYTE PTR [BX+3]
		JMP COLLPIECEBRK
LEFTDTEMP:									;move collision piece left 
		MOV BX, offset collisionPieceId
		DEC BYTE PTR [BX+2]
		JMP COLLPIECEBRK
RIGHTDTEMP:									;move collision piece right
		MOV BX, offset collisionPieceId
		INC BYTE PTR [BX+2]		
COLLPIECEBRK:
		CALL CheckCollision					;check if collisionPiece collides
											;AH will be 1 if it collides, 0 if not
		CALL DrawPiece
		POP BX
		CMP AH, 1
		JNZ	BREAKMOVEPIECE					;If the piece collides, break the procedure and leave

		;DELETE THE PIECE FROM THE SCREEN
		CALL DeletePiece
		;INSERT MOVING LOGIC HERE
	
		CMP BX, 0D
		JZ DOWND
		CMP BX, 1D
		JZ LEFTD
		CMP BX, 2D
		JZ RIGHTD
DOWND:			
		MOV BX, tempPieceOffset
		INC BYTE PTR [BX+3]
		JMP MOVPIECEBRK
LEFTD:
		MOV BX, tempPieceOffset
		DEC BYTE PTR [BX+2]
		JMP MOVPIECEBRK
RIGHTD:
		MOV BX, tempPieceOffset
		INC BYTE PTR [BX+2]
MOVPIECEBRK:	;DRAW THE NEW PIECE IN NEW LOCATION

		CALL DrawPiece
BREAKMOVEPIECE:
		POPA
		RET
MovePiece		ENDP
;---------------------------
;This procedure rotates the current piece that's pointed to by the tempPieceOffset by 90 degree from the previous rotation
;@param			SI: screenId: 0 for left, 4 for right
;@return		none
RotatePiece		PROC NEAR
		PUSHA
		CALL DeletePiece
		CALL GetTempPiece
		MOV SI,tempPieceOffset		;Loads the address of the current piece
		LEA DI,firstPiece
		
		MOV AL,[SI]					;Checks ID of the current piece and stores the offset of the original piece's Data in DI
		CMP AL,0
		JZ	ROTATE
		ADD DI,10H
		CMP AL,1
		JZ ROTATE
		ADD DI,10H
		CMP AL,2
		JZ ROTATE
		ADD DI,10H
		CMP AL,3
		JZ ROTATE
		ADD DI,10H
		CMP AL,4
		JZ ROTATE
		ADD DI,10H
		CMP AL,5
		JZ ROTATE
		ADD DI,10H					
		
ROTATE:										;Checks the current piece orientation to determine which loop to execute and updates the piece orientation
		INC SI	
		MOV AX,[SI]
		CMP AL,0
		JZ ROTATE90
		CMP AL,1
		JZ ROTATE180
		CMP AL,2
		JZ ROTATE270
		CMP AL,3
		JZ ROTATE360
		
ROTATE90:								;Rotates piece from 0 to 90
		MOV BL,1
		MOV [SI],BL
		ADD SI,3H				
		MOV AX,0CH
OUTER90:		MOV CX,4
		MOV BX,DI
		ADD BX,AX 
INNER90:		MOV DL,[BX]
		MOV [SI],DL
		INC SI
		SUB BX,4
		LOOP INNER90
		INC AX
		CMP AX,10H
		JZ BREAK
		JMP OUTER90
		
ROTATE180:								;Rotates piece from 90 to 180
		MOV BL,2
		MOV [SI],BL
		ADD SI,3H				
		MOV BX,DI
		ADD BX,0FH
OUTER180:		MOV DL,[BX]
		MOV [SI],DL
		INC SI
		DEC BX
		CMP BX,DI
		JS BREAK
		JMP OUTER180
				
ROTATE270:								;Rotates piece from 180 to 270
		MOV BL,3
		MOV [SI],BL
		ADD SI,3H
		MOV AX,3H
OUTER270:		MOV CX,4
		MOV BX,DI
		ADD BX,AX
INNER270:		MOV DL,[BX]
		MOV [SI],DL
		INC SI
		ADD BX,4
		LOOP INNER270
		DEC AX
		CMP AX,0
		JS BREAK
		JMP OUTER270
		
ROTATE360:								;Rotates piece from 270 to 0
		MOV BL,0
		MOV [SI],BL
		ADD SI,3H				
		MOV CX,16
		MOV BX,DI
OUTER360:		MOV DL,[BX]
		MOV [SI],DL
		INC SI
		INC BX
		LOOP OUTER360		
						
BREAK:			
		POPA
		CALL DrawPiece
		RET
RotatePiece		ENDP	
;---------------------------
;This procedure parses input and calls corresponding procedures
;@param			none
;@return		none
ParseInput		PROC	NEAR
		MOV AH, 1
		INT 16H
		JNZ YesInput
		RET
YesInput:
		MOV AH, 0
		INT 16H
LeftRotKey:
		CMP AH, leftRotCode
		JNZ LeftLeftKey

		MOV SI, 0
		CALL GetTempPiece

		MOV SI,0
		CALL RotatePiece

		JMP BreakParseInput
LeftLeftKey:
		CMP AH, leftLeftCode
		JNZ LeftDownKey
		MOV SI, 0
		CALL GetTempPiece

		MOV SI, 0
		MOV BX, 1
		CALL MovePiece

		JMP BreakParseInput
LeftDownKey:
		CMP AH, leftDownCode
		JNZ LeftRightKey
		MOV SI, 0
		CALL GetTempPiece

		MOV SI,0
		MOV BX,0
		CALL MovePiece


		JMP BreakParseInput
LeftRightKey:
		CMP AH, leftRightCode
		JNZ RightRotKey
		MOV SI, 0
		CALL GetTempPiece

		MOV SI,0
		MOV BX,2
		CALL MovePiece

		JMP BreakParseInput
RightRotKey:
		CMP AH, rightRotCode
		JNZ RightLeftKey
		MOV SI, 4
		CALL GetTempPiece

		MOV SI, 4
		CALL RotatePiece

		JMP BreakParseInput
RightLeftKey:
		CMP AH, rightLeftCode
		JNZ RightDownKey
		MOV SI, 4
		CALL GetTempPiece

		MOV SI, 4
		MOV BX, 1
		CALL MovePiece

		JMP BreakParseInput
RightDownKey:
		CMP AH, rightDownCode
		JNZ RightRightKey
		MOV SI, 4
		CALL GetTempPiece

		MOV SI, 4
		MOV BX, 0
		CALL MovePiece

		JMP BreakParseInput
RightRightKey:
		CMP AH, rightRightCode
		JNZ BreakParseInput
		MOV SI, 4
		CALL GetTempPiece
		
		MOV SI, 4
		MOV BX, 2
		CALL MovePiece

BreakParseInput:
		RET
ParseInput		ENDP
;---------------------------
;This Procedure is called in the gameloop to move the pieces downward each second
;@param			none
;@return		none
PieceGravity	PROC	NEAR
		PUSHA
		mov  AH, 2CH
		INT  21H 			;RETURN SECONDS IN DH.
		CMP DH,seconds		;Check if one second has passed
		JE NO_CHANGE
		MOV seconds,DH		;moves current second to the seconds variable
		MOV BX,0			;Parameter to move piece in particular direction
		MOV SI,0
		CALL GetTempPiece	;sets the TempPieceOffset with the address of the leftPiece
		MOV AX,0			;Clearing AX before using it
		MOV AX,tempPieceOffset ;gets the leftPiece's data offset
		ADD AX,14H			;Access the speed of the left piece
		MOV DI,AX			;DI=leftPieceSpeed
		MOV CX,0			;Clears the CX before looping
		MOV CL,[DI]			;moves the piece number of steps equal to it's speed
MOVELEFT:		CALL MovePiece	
		LOOP MOVELEFT
		
		MOV SI,4			
		CALL GetTempPiece	;sets the TempPieceOffset with the address of the rightPiece
		MOV AX,0			;Clearing AX before using it
		MOV AX,tempPieceOffset	;gets the rightPiece's data offset
		ADD AX,14H			;Access the speed of the right piece
		MOV DI,AX			;DI=rightPieceSpeed
		MOV CX,0			;Clears the CX before looping
		MOV CL,[DI]			;moves the piece number of steps equal to it's speed
MOVERIGHT:		CALL MovePiece	
		LOOP MOVERIGHT
		
NO_CHANGE:		POPA
		RET
PieceGravity	ENDP	
;---------------------------	


;---------------------------
;This procedure sets the collision piece by copying temp piece data to collision data
;@params	none
;@return 	none
setCollisionPiece	PROC	NEAR
			PUSHA

			MOV SI, tempPieceOffset  		;get the offset of the source data
			MOV DI, offset collisionPieceId	;offset of the destination data

			
			MOV CX, 21D						;loop 21 bytes to copy all the data
copyPieceData:		MOV BX, [SI]					;copy the data in byte to BX
			MOV [DI], BX					;paste the data in the destination byte
			INC DI							;increment destination offset
			INC SI							;increment source offset
			LOOP copyPieceData				;loop

			POPA
			RET
setCollisionPiece	ENDP
;---------------------------
;Procedure to check the collision with both the frame and blocks
;@params: NONE
;@return: AL: 1 collision, 0 no collision
CheckCollision	PROC	NEAR
				PUSHA

				CALL CheckCollisionWithFrame
				CMP AL, 1
				JE CollisionHappens

				CALL CheckCollisionWithBlocks
				CMP AL,1
				JE CollisionHappens

				MOV AL,0
				
				POPA
				RET
CollisionHappens: 
				MOV AL,1
				POPA
				RET

CheckCollision	ENDP
;---------------------------

;---------------------------
;Procedure to check the collision of the collisionPiece with the blocks
;@params: NONE
;@return: AL: 1 collision, 0 no collision
CheckCollisionWithBlocks	
				PROC	NEAR
				PUSHA

				MOV BX, offset collisionPieceId
				MOV DI, BX						;Load the piece 4x4 string address in pieceData
				ADD DI,	4						;Go to the string data to put in DI
				MOV CX, 0						;iterate over the 16 cells of the piece
				;if the piece has color !black, draw it with it's color
				;cell location is:
				;cell_x = orig_x + id%4
				;cell_y = orig_y + id/4

		loopOverPieceData:			
				MOV DL, [DI]					;copy the byte of color of current cell into DL
				CMP DL, 0D						;check if color of current piece block is black
				JZ	 checkNextByte

				;If byte has color
				PUSH CX

				MOV AX, CX
				MOV CL, 4D
				DIV CL						;AH = id%4, AL = id/4
				MOV CX, 0
				MOV DX, 0
				MOV CL, [BX+2]				;load selected piece X into CL
				MOV DL, [BX+3]				;load selected piece Y into DL
				ADD CL, AH					;CX = orig_x + id%4
				ADD DL, AL					;DX = orig_y + id/4

				CALL GetBlockClr

				CMP AL, 0D
				POP  CX
				JNZ collisionWithBlockHappens 

				
			
			checkNextByte:
				INC CX		
				INC DI
				CMP CX, 16D
				JNZ loopOverPieceData
				

				MOV AL,0D
				POPA
				RET

				collisionWithBlockHappens:


				MOV AL,1D
				POPA
				RET

CheckCollisionWithBlocks	ENDP
;---------------------------

CheckCollisionWithFrame	PROC	NEAR
						PUSHA

		MOV BX, offset collisionPieceId
		MOV DI, BX						;Load the piece 4x4 string address in pieceData
		ADD DI,	4						;Go to the string data to put in DI
		MOV CX, 0D						;iterate over the 16 cells of the piece
		;if the piece has color !black, draw it with black
		;cell location is:
		;cell_x = orig_x + id%4
		;cell_y = orig_y + id/4
CheckCollisionWithFrameLoop:			
		MOV DL, [DI]					;copy the byte of color of current cell into DL
		CMP DL, 0D						;check if color of current piece block is black
		JZ 	blockEmpty
		
		PUSH CX
		
		MOV AX, CX
		MOV CL, 4D
		DIV CL						;AH = id%4, AL = id/4
		MOV CX, 0
		MOV DX, 0
		MOV CL, [BX+2]				;load selected piece X into CL
		MOV DL, [BX+3]				;load selected piece Y into DL
		ADD CL, AH					;CX = orig_x + id%4
		ADD DL, AL					;DX = orig_y + id/4
		
		CMP CX, FRAMEWIDTH
		JAE outOfScreen
		CMP DX, FRAMEHEIGHT
		JAE outOfScreen 
		 
		POP  CX
blockEmpty:		
		INC CX
		INC DI
		CMP CX, 16D
		JNZ CheckCollisionWithFrameLoop

		MOV AL,0
		POPA
		RET

outOfScreen:
			MOV AL,1
			POP  CX
			POPA
			RET


CheckCollisionWithFrame	ENDP
;---------------------------

END     MAIN