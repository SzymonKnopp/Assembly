; Copyright 2020, Szymon Knopp

; assumes that no symbols other than digits or capitalized letters are put in
; greatest operable number is 4294967295 (2^32 - 1), the upper limit of 32-bit registers
; greatest operable numeral system has base of 36 (to increase, add symbols to the encoder)

.686
.model flat

extern _ExitProcess@4 : PROC
extern __read : PROC
extern __write : PROC

public _main

.data
	inputNumberSystem dd 2		; double word to force 64-bit multiplication, to avoid loss of data by the number being out of bounds
	outputNumberSystem dd 10	; double word to force 64-bit division, to avoid overwriting data in EAX
	maxStringLength dd 33		; FF FF FF FFh = 1111 1111 1111 1111 1111 1111 1111 1111b
								; (max number stored in register takes 8*4=32 digits in the smallest number system +1 for 'enter' or delimiter)
	encoder db "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"

.code
readToEAX PROC
	push EBX
	push ECX
	push EDX
	push ESI
	push EDI
	push EBP

	mov EBP, ESP
	sub ESP, maxStringLength
	mov ESI, ESP
	
	push maxStringLength
	push ESI
	push dword PTR 0
	call __read
	add ESP, 12 ; deallocating of __read arguments

	mov EAX, 0
	mov EBX, 0

addDigit:
	mov BL, [ESI]
	cmp BL, 10 ; check if enter (line feed) reached
	je numberAccumulated

	;check if is in 0-9 and prepare
	cmp BL, '0'
	jb notaNumber
	cmp BL, '9'
	ja notaNumber
	sub BL, '0'
	jmp digitReady

notaNumber:
	;check if is in A-Z and prepare
	cmp BL, 'A'
	jb notaLetter
	cmp BL, 'Z'
	ja notaLetter
	sub BL, 'A'
	add BL, 10
	jmp digitReady
	
notaLetter:
	;ERROR - invalid symbol put in!
	
digitReady:
	mul inputNumberSystem
	add EAX, EBX
	inc ESI ; point to the next digit
	jmp addDigit

numberAccumulated:

	add ESP, maxStringLength ; deallocating memory

	pop EBP
	pop EDI
	pop ESI
	pop EDX
	pop ECX
	pop EBX
	ret
readToEAX ENDP

writeFromEAX PROC
	pushad

	mov EBP, ESP
	sub ESP, maxStringLength
	mov EDI, EBP
	mov EDX, 0 ; EDX is used in 64-bit division

	mov [EDI], byte PTR 0 ; delimiter for __write
	dec EDI

calculateDigit:
	cmp EAX, 0
	je numberParsed
	mov EDX, 0
	div outputNumberSystem

	add EDX, OFFSET encoder
	mov DL, [EDX] ; encode a digit

	mov [EDI], DL
	dec EDI ; point to the next digit slot
	jmp calculateDigit

numberParsed:
;fillWithSpaces:
;	cmp EDI, ESP
;	je numberReady
;	mov [EDI], byte PTR ' '
;	dec EDI
;	jmp fillWithSpaces

;numberReady:
	
	mov EDX, EBP
	sub EDX, EDI ; calculate number of digits to write
	sub EDX, 1

	inc EDI ; return to the oldest digit

	push EDX
	push EDI
	push 1
	call __write
	add ESP, 12 ; deallocating of __write arguments

	add ESP, maxStringLength

	popad
	ret
writeFromEAX ENDP

_main PROC
	call readToEAX
	call writeFromEAX

	push 0
	call _ExitProcess@4
_main ENDP
END