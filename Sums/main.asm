data segment

data edns
	INPUT_NAME  db ? 256 dup(0)
	OUTPUT_NAME db ? 256 dup(0)
	BUFFER		db ? 1024 dup(' ') ;Wypychamy sobie spacjami żeby łatwiej się pobierało wejscie 
	BUFFER_n	db 0
	ERROR1		db "Nie podano argumentow"
	ERROR2		db "Zbyt malo argumentow"
	ERROR3		db "Podano zbyt duzo argumentow"
code segment
start:

	call Input ;Pobiera ciąg znaków z wejscia
	call Parser ;Sprawdzam wejscie
	call Debug

	mov AX, seg stack_pointer	;inicjalizacja stosu
    mov SS, AX					;Segment Stosu
    lea SP, SS:[stack_pointer]	;Wskaźnik na wierzchołek stosu    

    KONIECPROGRAMU:
    mov AX, 4C00h				;zakoncz program
    int 21h

Input proc
	mov AX, seg data
	mov ES, AX

	xor CX, CX
	mov  CL, byte ptr DS:[080h] ;pobieram ilość znaków
	inc CX ;inkrementuje to po to żeby pobrać znak końca stringu
	
	lea SI, DS:[081h]
	lea DI, ES:[BUFFER]
	rep movsb ;Kopiujemy argumenty do BUFFER

	xor DX, DX 					
	mov DL, byte ptr DS:[080h] ;Zapamietuje w DL pobraną ilość znaków
	mov AX, seg data
	mov DS, AX
	mov byte ptr DS:[BUFFER_n], DL		;zapisuje pobrana ilosc znakow w BUFFER_n
	ret
Input ends

;Parasujemy BUFFER, zapisujemy nazwy plików, sprawdzamy czy zostały podane argumenty
Parser proc
	cmp BUFFER_n, 0 ;Porownuje ilosc znakow do zera
	ja @@OK	;Jezeli BUFFER_n = 0 -> nie podanno argumentow
		mov AX, seg ERROR1
		mov DS, AX
		mov DX, offset ERROR1
		mov AH, byte ptr 9 ;Wypisuje informacje o bledzie
		int 21h
		jmp KONIECPROGRAMU ;Koncze program
	@@OK:	
	;Wiemy ze urzytkownik podal jakies argument/argumenty
	;Pobieramy pierwszy argumen
	;Pobieramy znaki az trafimy na spacje lub BUFFER_n = 0
	lea SI, DS:[BUFFER]  ;ustawiamy wskaźnik na poczatek wejsciowego ciagu
	call GoThroughSpaces ;przesuwamy sie po spacjach do pierwszego argumentu
	cmp AL, 13 ;Po przejciu po spacjach sprawdzamy czy czasami nie znalezlismy sie na koncu stringa
	jne @@first_parameter
		;jezeli znalezlismy sie wewnącz znaczy że nie znaleźlismy żednego argumentu
		mov AX, seg ERROR1
		mov DS, AX
		mov DX, offset ERROR1
		mov AH, byte ptr 9 ;Wypisuje informacje o bledzie
		int 21h
		jmp KONIECPROGRAMU ;Koncze program
	@@first_parameter:

	mov DI, DS:[INPUT_NAME] ;bede zapisywal do INPUT_NAME
	call FileName ;Pobieram inputname do INPUT_NAME

	call GoThroughSpaces ;przesuwamy sie po spacjach do drugiego argumentu
	cmp AL, 13 ;Po przejciu po spacjach sprawdzamy czy czasami nie znalezlismy sie na koncu stringa
	jne @@first_parameter
		;jezeli znalezlismy sie wewnącz znaczy że nie znaleźlismy drugiego argumentu
		mov AX, seg ERROR2
		mov DS, AX
		mov DX, offset ERROR2
		mov AH, byte ptr 9 ;Wypisuje informacje o bledzie
		int 21h
		jmp KONIECPROGRAMU ;Koncze program
	@@first_parameter:

	mov DI, DS:[OUTPUT_NAME]
	call FileName ;Pobieram outputname chwilowo do inputname

	call GothroughSpaces ;przechodze spacje ktore mogly byc na koncu
	cmp AL, 13 ;Po przejciu po spacjach sprawdzamy znalezlismy sie na koncu stringa
	je @@second_parameter
		;jezeli znalezlismy sie wewnacz, znaczy ze mamy za duzo argumentow
		mov AX, seg ERROR3
		mov DS, AX
		mov DX, offset ERROR3
		mov AH, byte ptr 9 ;Wypisuje informacje ze zostalo podane zbyt duzo argumentow
		int 21h
		jmp KONIECPROGRAMU ;Koncze program
	@@second_parameter:
	;Jezeli wszystko zakoczylo sie poprawnie w INPUT_NAME mamy nazwe pliku wejsciowego
	; a w pliku OUTPUT_NAME mamy nazwe pliku do ktorego mamy zapisac wyjscie
	ret
Parser endp

GoThroughSpaces proc
	@@GoThroughSpaces_loop
		mov AL, DS:[SI] ;Pobieramy kolejny znak do AL
		cmp AL, 13 ;Sprawdzamy czy mamy znak zakonczenia stringu
		je @@END ;Jezeli tak to konczymy przeszukiawnie
		cmp AL, 32 ;Sprawdzamy czy trafiliśmy na spacje
		je @@END ;jeżeli nie to mamy znak ktorym zaczyna się kolejny parametr, konczymy przeszukiawnie spacji
		int SI ;Mamy kolejna spacje, wiec przesuwamy sie na koleny znak
	jmp @@GothroughSpaces_loop
	@@END
	ret
GothroughSpaces endp

FileName proc
	xor AX, AX
	@@FileName_loop:
		mov AL, DS:[SI]
		cmp AL, 13 ;Koniec Stringa?
		je @@FileName_end
		cmp AL, 32 ;Kolejna spacja?
		je @@FileName_end
		movsb ;kopiuje znak z DS:[SI] do DS:[DI]
	jmp @@FileName_loop
	@@FileName_end
	ret
FileName endp

Debug proc ;funkcja tylko do debugowania
	mov AX, seg INPUT_NAME
	mov DS, AX
	mov DS, offset INPUT_NAME
	mov DS:[INPUT_NAME+250], '$' ;dodaje na koncu $
	mov AH, 9
	int 21h
	mov DX, offset OUTPUT_NAME
	mov DS:[OUTPUT_NAME+250], '$'
	mov AH, 9
	int 21h
	ret
Debug enrp

code ends

stack segment stack
                dw  20 dup(?) 
stack_pointer   dw  ?           
stack ends

end start