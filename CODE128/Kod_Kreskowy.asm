data segment
	enc_tab       db "11011001100", "11001101100", "11001100110", "10010011000"
				  db "10010001100", "10001001100", "10011001000", "10011000100"
				  db "10001100100", "11001001000", "11001000100", "11000100100"
				  db "10110011100", "10011011100", "10011001110", "10111001100"
				  db "10011101100", "10011100110", "11001110010", "11001011100"
				  db "11001001110", "11011100100", "11001110100", "11101101110"
				  db "11101001100", "11100101100", "11100100110", "11101100100"
				  db "11100110100", "11100110010", "11011011000", "11011000110"
				  db "11000110110", "10100011000", "10001011000", "10001000110"
				  db "10110001000", "10001101000", "10001100010", "11010001000"
				  db "11000101000", "11000100010", "10110111000", "10110001110"
				  db "10001101110", "10111011000", "10111000110", "10001110110"
				  db "11101110110", "11010001110", "11000101110", "11011101000"
				  db "11011100010", "11011101110", "11101011000", "11101000110"
				  db "11100010110", "11101101000", "11101100010", "11100011010"
				  db "11101111010", "11001000010", "11110001010", "10100110000"
				  db "10100001100", "10010110000", "10010000110", "10000101100"
				  db "10000100110", "10110010000", "10110000100", "10011010000"
				  db "10011000010", "10000110100", "10000110010", "11000010010"
				  db "11001010000", "11110111010", "11000010100", "10001111010"
				  db "10100111100", "10010111100", "10010011110", "10111100100"
				  db "10011110100", "10011110010", "11110100100", "11110010100"
				  db "11110010010", "11011011110", "11011110110", "11110110110"
				  db "10101111000", "10100011110", "10001011110", "10111101000"
				  db "10111100010", "11110101000", "11110100010", "10111011110"
				  db "10111101110", "11101011110", "11110101110"
	code_start_a  db "11010000100"
	code_start_b  db "11010010000"
	code_start_c  db "11010011100"
	code_stop     db "1100011101011" 
	kolor		  db 15
	X			  dw 20
	Y			  db 20
	BUFFOR		  db 17
	BUFFOR_n	  db 0
	BUFFOR_w      db 17 dup(0)
	CheckChar     dw 0
	ERROR1		  db "Nie podano argumentow", 13, 10, '$'
	ERROR2		  db "Za dlugi ciag znakow", 13, 10, '$'
data ends

code segment
start:
     
	mov AX, seg data
	mov ES, AX
	 
	xor CX, CX
	mov  CL, byte ptr DS:[080h]
	
	call Input 					;sprawdza czy dlugosc ciagu znakow jest odpowiednia
	
	inc CX
	
	lea SI, DS:[081h]
	lea DI, ES:[BUFFOR_w]
	rep movsb
	
	xor DX, DX 					;zapamietuje ilosc znakow
	mov DL, byte ptr DS:[080h]
	
	mov AX, seg data
	mov DS, AX
	 
	mov byte ptr DS:[BUFFOR_n], DL		;zapisuje pobrana ilosc znakow
	
	
	
	mov AX, seg stack_pointer	;inicjalizacja stosu
    mov SS, AX
    lea SP, SS:[stack_pointer]
    
	mov AH, 00					;rozpoczynamy prace w trybie 13h
    mov AL, 13h
    int 10h 
     
	
	call FillBackground			;wypelnia tlo
	call main					;jezeli dane zostaly poprawie pobrane
								;rysuje kod
	
	call CzekajNaESC			;czekaj na wcisniecie esc
	
	KONIECPROGRAMU:
    mov AX, 4C00h				;zakoncz program
    int 21h

CzekajNaESC proc
	@@CZEKAJ:
	in AL, 60h
	cmp AL, 81h
	jne @@CZEKAJ
	ret
CzekajNaESC endp
	
Input proc
	xor AX, AX							;sprawdzamy czy pobralismy jakies znaki
	mov AL, CL
	cmp AX, 0
	ja @@OK
		mov AX, seg ERROR1
		mov DS, AX
		mov DX, offset ERROR1
		mov AH, byte ptr 9
		int 21h
		jmp KONIECPROGRAMU
	@@OK:
	
	cmp AX, 17							;sprawdzamy czy nie pobralismy ich za duzo
	jna @@OK1
		mov AX, seg ERROR2
		mov DS, AX
		mov DX, offset ERROR2
		mov AH, byte ptr 9
		int 21h
		jmp KONIECPROGRAMU
	@@OK1:
	
	ret
Input endp
	
PrintLine proc						;funkcja rysujaca linie pionowa
	mov CX, 100
	@@Petla:
	push CX
		add CX, 50
		mov AX, 0A000h
		mov ES, AX
		mov AX, CX
		mov DI, 320
		mul DI
		
		push AX
		mov AX, seg X
		mov DS, AX
		pop AX
		
		add AX, word ptr DS:[X]
		mov DI, AX
		mov AL, byte ptr DS:[Kolor]
		mov byte ptr ES:[DI], al		
		
	pop CX
	loop @@Petla
	ret
PrintLine endp
 
FillBackground proc 			;funkcja malujaca tlo na bialo
    .486
    mov byte ptr DS:[Kolor], 15 			;ustawiam kolor tla na biale
	mov cx, 16000
    mov al, byte ptr DS:[Kolor]
    mov bl, al
    mov ah, al
    shl eax, 16
    mov al, bl
    mov ah, al
    mov bx, 0A000h
    mov es, bx
    xor di, di
    cld
    rep stosd
    
    ret
 FillBackground endp
 
UstawX proc
	xor AX, AX
	mov AL, byte ptr DS:[BUFFOR_n]					;pobieram dlugosc tablicy wejsciowej
	mov BX, 11								;mnozymy wszystko przez dlugosc jednego znaku w pikselach
	mul BX
	mov BX, 320
	sub BX, AX								;odejmujemy wszystko od 320pkseli
	mov AX, BX
	mov BX, 2								;dzielimy przez 2 zeby zostawic miejsce na StopCode i CheckCharacter
	div BX
	
	sub AX, 11								;odejmuje od X 11 zeby zostawic miejsce na quietzone i na StartCode
	mov word ptr DS:[X], AX					;zapamietuje wszystko w X
	ret
UstawX endp
 
CheckCharacter proc
    mov DS:[CheckChar], 104 				;dodaje kod 104 do sumy
    xor CX, CX
	mov CL, DS:[BUFFOR_n] 					;funkcja przechodzi cala tablice wejsciowa
	@@CheckCharacterLoop:
	push CX									;wyciagam po kolei elementy z tablicy
		xor BX, BX 							;zeruje BX
		mov BL, byte ptr DS:[BUFFOR_n];		;pobieram ilosc znaków w tablicy
		sub BX, CX							;Odejmuje od BX, CX zeby przesuwac sie od lewej do prawej
		xor AX, AX							
		mov AL, byte ptr DS:[BUFFOR_w+BX]	;pobieram znak
		sub AL, 32d                         ;odejmuje 32 zeby dostać kod 128
		add BX, 1							;inkrementuje BX zeby mnozyc kolejne znaki przez 1, 2, 3, ...
		mul BX                
	    add word ptr DS:[CheckChar], AX     ;dlaczego add DS:[CheckChar], AX nie działas
	    
	pop CX	
	loop @@CheckCharacterLoop 
	
	mov AX, word ptr DS:[CheckChar]			;dzielimy przez 103
	mov BX, 103	
	div BX
	mov word ptr DS:[CheckChar], DX			;zapamietujemy reszte z dzielenia
    ret
CheckCharacter endp
 
main proc
	xor CX, CX
	mov CL, byte ptr DS:[BUFFOR_n]			;pobieram ilosc pobranych znakow do CX
	call UstawX								;ustawiam odpowiednio X zeby rysowac na srodku ekranu
	mov byte ptr DS:[Kolor], 0				;ustawiam kolor rysowania na czarny

	mov CX, 11 								;Wypiszuje StartCode
	@@StartCode:
	push CX  
	    xor BX, BX
		mov BL, 11
		sub BX, CX
        xor AX, AX
		mov AL, byte ptr DS:[code_start_b+BX]  
		cmp AL, '1'							;sprawdzamy czy mamy 1
		jnz @@StartCodeZERO					;jezeli mamy '1' rysujemy prosta
	        call PrintLine
		@@StartCodeZERO:
		inc byte ptr DS:[X] ;				;przesuwamy sie w lewo

	pop CX
	loop @@StartCode;

	xor CX, CX
	mov CL, byte ptr DS:[BUFFOR_n] 			;przechodzi cala tablice
	@@MainLoop:
	push CX
		xor BX, BX ;zeruje BX				;wyciagam po kolei elementy z tablicy
		mov BL, byte ptr DS:[BUFFOR_n] 				;pobieram ilosc znaków w tablicy
		sub BX, CX	
		xor AX, AX
		mov AL, byte ptr DS:[BUFFOR_w+BX] 	;pobieram znak
		sub AL, 32d							;odejmuje 32 zeby dostać kod 128
		mov BX, 11d							;mnoze przez 11 zeby przesunac sie odpowiednio w tablicy
		mul BX
		xor CX, CX 							;zeruje CX
		call WypiszZnak
	pop CX
	loop @@MainLoop

	call CheckCharacter						;licze sume kontrolna modulo 103
	mov AX, word ptr DS:[CheckChar] 		;pobieram z pamieci
	mov BX, 11 								;mnoze przez 11 zeby przesunac sie wzgledem tablicy
	mul BX
	call WypiszZnak 						;wypisuje znak rowny sumie kontrolnej
	
	;StopCode
	mov CX, 13 								;Wypiszuje StopCode
	@@StopCode:
	push CX  
	    xor BX, BX
		mov BL, 13							;StopeCode ma dlugosc 13
		sub BX, CX
        xor AX, AX
		mov AL, byte ptr DS:[code_stop+BX] 	;Przesuwamy sie po tablicy i wypisujemy linie jest AX = 1
		cmp AL, '1' 						;sprawdzamy czy mamy 1, jesli tak to wypisujemy kreske
		jnz @@StopCodeZERO
	        call PrintLine
		@@StopCodeZERO:
		inc DS:[X] 							;przesuwamy wskaznik w prawo
	pop CX
	loop @@StopCode;
	
	
	ret
main endp

;funkcja pobiera z AX numer znaku ktory mamy zakodowac
;pobiera i rysuje 11 kolejnych elementow z tablicy
WypiszZnak proc
		mov CX, 11 						;ustawiam CX zeby pobrac 11 kolejnych znakow
		@@WypiszZnak_Pobieraj:
		push CX
			push AX 					;zapamietuje pobrana wartosc znaku w c128
			xor BX, BX 					;zeruje BX'a
			mov BL, 11 					;mnoze przez 11 zeby przesunac sie odpowiednio w tablicy
			sub BX, CX
			
			add AX, BX 
			mov BX, AX 
            xor AX, AX
			mov AL, byte ptr DS:[enc_tab+BX]	
			cmp AL, '1'					;sprawdzamy czy mamy 1  
			jnz @@ZERO
	            call PrintLine			;jezeli AX=1 rysuje prosta
			@@ZERO:
		    pop AX 						;pobieram spowrotem id znaku
		pop CX       
		inc word ptr DS:[X]
		loop @@WypiszZnak_Pobieraj
    ret
WypiszZnak endp
	
code ends

stack segment stack
                dw  20 dup(?)   ; 63 + 1 = 64
stack_pointer   dw  ?           
stack ends


end start