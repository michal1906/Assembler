data segment
  INPUT_NAME    db 256 dup(0) ;Nazwa pliku wejsciowego
  OUTPUT_NAME   db 256 dup(0) ;Nazwa pliku wyjsciowego
  BUFFER        db 4096 dup(0), 0 ;Tutaj wczytuje bloki danych
  BUFFER_n      db 0 ;Rozmiar pobranych parametrow
  ERROR1        db "Nie podano argumentow $"
  ERROR2        db "Zbyt malo argumentow $"
  ERROR3        db "Podano zbyt duzo argumentow $"
  OpenFile_error          db "Nie udalo sie otworzyc pliku $"
  SaveBuffer_error        db "Nie udało się zapisać raportu $"
  HEAD                    db "Raport z pliku o nazwie: "
  CloseFile_error         db "Nie udalo sie zamknac pliku $"
  Read_error              db "Nie udalo sie odczytac danych z pliku $"
  NewFile_error           db "Nie udalo sie utworzyc nowego pliku $"
  FILE_HANDLE             dw 0 ;Uchwyt na otwarty plik
  RES_TABLE               dd 256 dup(0) ;Tablica z wynikami
      
data ends
code segment
start:

    call Input ;Funkcja pobierajaca wejscie do buffora

    mov AX, seg stack_pointer ;inicjalizacja stosu
    mov SS, AX          ;Segment Stosu
    lea SP, SS:[stack_pointer]  ;Wskaźnik na wierzchołek stosu  

    call Parser

    mov AX, seg INPUT_NAME
    mov DS, AX ;zapamietuje segment danych w DS i ES
    mov ES, AX

    lea DX, DS:[INPUT_NAME] ;Laduje do DX nazwe otwieranego pliku
    call OpenFile   ;Otwieram plik wejsciowy
    call Analyse ;Analizuje dane z pliku
    call CloseFile ;Zapykam plik wejsciowy  

    call NewFile ;Tworzy nowy plik 
    call GenerateBuffer ;Zapisuje wyniki do BUFFER
    call SaveBuffer ;Zapisuje BUFFER w pliku

    call CloseFile ;Zamykam plik wyjsciowy
    
    KONIECPROGRAMU:
    mov AX, 4C00h       ;zakoncz program
    int 21h
    
Input proc
    mov AX, seg data
    mov ES, AX

    xor CX, CX
    mov  CL, byte ptr DS:[080h] ;pobieram ilość znaków
    inc CX ;inkrementuje to po to żeby pobrać znak końca stringu
    
    lea SI, DS:[081h] ;w 081h mamy ilosc parametrow
    lea DI, ES:[BUFFER] ;wskaznik na poczatek bufora
    rep movsb ;Kopiujemy argumenty do BUFFER

    xor DX, DX                  
    mov DL, byte ptr DS:[080h] ;Zapamietuje w DL pobraną ilość znaków
    mov AX, seg data 
    mov DS, AX
    mov byte ptr DS:[BUFFER_n], DL      ;zapisuje pobrana ilosc znakow w BUFFER_n
    ret
Input endp

;Parasujemy BUFFER, zapisujemy nazwy plików, sprawdzamy czy zostały podane argumenty
Parser proc
    cmp DS:[BUFFER_n], 0 ;Porownuje ilosc znakow do zera
    ja @@OK ;Jezeli BUFFER_n = 0 -> nie podanno argumentow
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

    lea DI, DS:[INPUT_NAME] ;bede zapisywal do INPUT_NAME
    call FileName ;Pobieram inputname do INPUT_NAME
    
    cmp AL, 13 ;sprawdzamy czy po pobraniu nazwy nie znajdujemy sie na koncu stringa
    jne @@not_end
        ;jezeli znalezlismy sie wewnącz znaczy że nie znaleźlismy drugiego argumentu
        mov AX, seg ERROR2
        mov DS, AX
        mov DX, offset ERROR2
        mov AH, byte ptr 9 ;Wypisuje informacje o bledzie
        int 21h
        jmp KONIECPROGRAMU ;Koncze program
    @@not_end:


    call GoThroughSpaces ;przesuwamy sie po spacjach do drugiego argumentu
    cmp AL, 13 ;Po przejciu po spacjach sprawdzamy czy czasami nie znalezlismy sie na koncu stringa
    jne @@second_parameter
        ;jezeli znalezlismy sie wewnącz znaczy że nie znaleźlismy drugiego argumentu
        mov AX, seg ERROR2
        mov DS, AX
        mov DX, offset ERROR2
        mov AH, byte ptr 9 ;Wypisuje informacje o bledzie
        int 21h
        jmp KONIECPROGRAMU ;Koncze program
    @@second_parameter:

    lea DI, DS:[OUTPUT_NAME]
    call FileName ;Pobieram outputname

    cmp AL, 13 ;sprawdzamy czy po pobraniu nazwy nie znajdujemy sie na koncu stringa
    je @@end_of_input ;jezeli tak to konczymy wszystko porawnie

    call GothroughSpaces ;przechodze spacje ktore mogly byc na koncu
    cmp AL, 13 ;Po przejciu po spacjach sprawdzamy znalezlismy sie na koncu stringa
    je @@end_of_input
        ;jezeli znalezlismy sie wewnacz, znaczy ze mamy za duzo argumentow
        mov AX, seg ERROR3
        mov DS, AX
        mov DX, offset ERROR3
        mov AH, byte ptr 9 ;Wypisuje informacje ze zostalo podane zbyt duzo argumentow
        int 21h
        jmp KONIECPROGRAMU ;Koncze program
    @@end_of_input:
    ;Jezeli wszystko zakoczylo sie poprawnie w INPUT_NAME mamy nazwe pliku wejsciowego
    ; a w pliku OUTPUT_NAME mamy nazwe pliku do ktorego mamy zapisac wyjscie
    ret
Parser endp

;Funkcja przechodzi wszystkie spacje az do natrafienia jakiegos znaku
GoThroughSpaces proc
    @@GoThroughSpaces_loop:
        mov AL, DS:[SI] ;Pobieramy kolejny znak do AL
        cmp AL, 13 ;Sprawdzamy czy mamy znak zakonczenia stringu
        je @@END ;Jezeli tak to konczymy przeszukiawnie
        cmp AL, 32 ;Sprawdzamy czy trafiliśmy na spacje
        jne @@END ;jeżeli nie to mamy znak ktorym zaczyna się kolejny parametr, konczymy przeszukiawnie spacji
        inc SI ;Mamy kolejna spacje, wiec przesuwamy sie na koleny znak
    jmp @@GothroughSpaces_loop
    @@END:
    ret
GothroughSpaces endp

FileName proc
    xor AX, AX
    @@FileName_loop:
        mov AL, DS:[SI] ;Pobieram kolejny znak
        cmp AL, 13 ;Koniec Stringa?
        je @@FileName_end
        cmp AL, 32 ;Kolejna spacja?
        je @@FileName_end
        movsb ;kopiuje znak z DS:[SI] do DS:[DI]
    jmp @@FileName_loop
    @@FileName_end:

    push AX
    mov AL, 0 ;Dodaje 0 na koncu nazwy pliku
    mov DS:[SI], AL
    inc SI
    pop AX

    ret
FileName endp

OpenFile proc   
  
  mov AH, 3dh ; funkcja otwierajaca
  mov AL, 0 ; 0 - plik tylko do odczytu
  int 21h
  
  ;jezeli CF != 0, nie udalo sie otworzyc pliku
  jc @@OpenFile_error
    
    mov DS:[FILE_HANDLE], AX ;Zapamietuje uchwyt otwartego pliku
    ret
  
  @@OpenFile_error:
    mov DX, offset DS:[OpenFile_error] ;Wywal Error
    mov AH, 9
    int 21h
    jmp KONIECPROGRAMU ;zakocz program

OpenFile endp  

NewFile proc
    mov AH, 3Ch ;Funkcja 3Ch otwiera plik
    xor CX, CX ;W CX ma podane atrybuty
    lea DX, DS:[OUTPUT_NAME] ;Nazwa pliku wyjsiowego
    int 21h
    mov DS:[FILE_HANDLE], AX ;Zapamietuje uchwyt nowego pliku
    jc @@NewFile_error
        ret
    @@NewFile_error:
        lea DX, DS:[NewFile_error] ;jezeli nie udalo sie otworzyc pliku, wypisz error
        mov AH, 9   
        int 21h
        jmp KONIECPROGRAMU
NewFile endp

;Read zwraca do AX ilosc zczytanych bajtow       
Read proc
    mov BX, DS:[FILE_HANDLE] ;uchwyt pliku
    lea DX, DS:[BUFFER] ;addres buffora   
    mov AH, 3Fh ;Funkcja czytajaca z pliku
    int 21h
    jc @@Read_error
        ret
    @@Read_error:
        lea DX, DS:[Read_error] ;wypisz info. o bledzie
        jmp KONIECPROGRAMU
Read endp            
  
Analyse proc
    
    lea SI, DS:[BUFFER] ; Adress buffora
    mov CX, 4096 ;Tyle bajtow bedziemy pobierac
    
    @@Analyse_loop:
        call Read ;wczytaj bajty z pliku, AX-ile bajtow pobrano  
        
        push CX
        push AX
          mov CX, AX ;Zapamietaj ile danych pobrano
          call AnalyseBuffer ;Analizuj pobrane dane
        pop AX
        pop CX
        
    cmp AX, CX ;jezeli pobrano mniej niz CX to mamy koniec pliku
    jae @@Analyse_loop      
    ret
Analyse endp

;AnalyseBuffer(buffer, CX)
AnalyseBuffer proc
  push CX
  push SI
    AnaluseBuffer_loop: 
    cmp CX, 0
    je AnalyseBuffer_end     
    
      xor AX, AX
      mov AL, DS:[SI] ;pobieram kolejny bit
      lea DI, DS:[RES_TABLE] ;wskaznik na tablice wynikow
      mov BL, 4 ;mnoze to przez 4 poniewaz tablica RES_TABLE jest podwojnym slowem
      mul BL
      add DI, AX ;Przesuwam sie w tablicy
              
      add word ptr DS:[DI], 1 ;Inkrementuje wynik
      adc word ptr DS:[DI+2], 0 ;wynik jest podwójnym słowem
      ; adc = add with carry
      ; sumuje A, B oraz flage CF
    
      inc SI ;Przesuwam sie w tablicy BUFFER
      dec CX
    
    jmp AnaluseBuffer_loop 
    AnalyseBuffer_end:
  
  pop SI
  pop CX
    ret
AnalyseBuffer endp   

GenerateBuffer proc
push CX
push SI
push AX
push DX

  
  lea DI, ES:[BUFFER] ;Wskaznik na buffor

  ; Zapisz tytul do buffora
   lea SI, DS:[HEAD]
   mov CX, 25
   HEAD_loop:
   push CX
      mov AL, byte ptr DS:[SI]
      mov ES:[DI], AL
      inc SI
      inc DI 
   pop CX
   loop HEAD_loop
  
  ; zapisz nazwe pliku do buffora
    lea SI, DS:[INPUT_NAME]
    call SizeOfaBuffer
    NAME_loop:
    push CX
        mov AL, byte ptr DS:[SI]
        mov ES:[DI], AL
        inc SI
        inc DI
    pop CX
    loop NAME_loop

    ;dodaje przejscie do nowej lini do BUFFER
   mov AL, 10
   mov ES:[DI], AL
   inc DI

  lea SI, DS:[RES_TABLE] ;Tablica z wynikami w dd
  xor AX, AX
  mov AX, 0 ;Przechdze cala tablice RES_TABLE
  GenerateBuffer_loop:
  push AX
    
    ; Zapisz numer bajtu do pliku
      call SaveByteID

    ; Zapisz dwukropek
      call SaveColon

    push AX
    push DX
        ;zapisuje kolejną liczbę w DX:AX
        mov AX, DS:[SI]
        mov DX, DS:[SI+2]
        call RenderDWORD ;Zapisuje liczbe do buffora w postaci dziesietnej
    pop DX
    pop AX

    add SI, 4 ;przesuwam sie po kolejny element w tablicy RES_TABLE
  
  pop AX
  inc AX
  cmp AX, 255
  ja GenerateBuffer_end
  jmp GenerateBuffer_loop

  GenerateBuffer_end:  

  ;Dodajemy znak konca stringu
  mov AL, 0
  mov ES:[DI], AL

pop DX
pop AX
pop SI
pop CX

  ret
GenerateBuffer endp

;Fukcja zapisujaca ':' do ES:DI
SaveColon proc
  mov ES:[DI], byte ptr ':'
  inc DI
  ret
SaveColon endp

;Funkcja zapisuj ID bajtu do ES:[DI]
SaveByteID proc
  push AX
  push BX

  ;Najpierw czesc setną
  mov BL, 100
  div BL
  add AL, '0'
  mov ES:[DI], AL
  inc DI

  ;Część dziesiętną
  mov AL, AH
  cbw
  mov BL, 10
  div BL
  add AL, '0'
  mov ES:[DI], AL
  inc DI

  ;Jedności
  add AH, '0'
  mov ES:[DI], AH
  inc DI

  pop BX
  pop AX
  ret
SaveByteID endp

;Funkcja zapisuje podwójne społo w postaci dziesiętnej do buffor
;Dzielimy przez 10 a cyfry wkładamy na stos
RenderDWORD proc
  
  ;Sprawdzamy czy liczba = 0, jezeli tak to zapisujemy do ES:[DI] zero
  cmp DX, 0
  jne @@not_zero
  cmp AX, 0
  jne @@not_zero

  mov AL, '0'
  mov ES:[DI], AL
  inc DI
  jmp @@end

  ;Jezeli nie jest zerem to dzielimy to przez 10
  @@not_zero:
  xor BX, BX
  xor CX, CX
     RenderDWORD_loop:
            ;sprwadzamy czy nalezy dalej dzielic
          cmp DX, 0
          jne RenderDWORD_work
          cmp AX, 0
          je RenderDWORD_end

          RenderDWORD_work:
               call DivBy10 ;dzielenie przez 10
               push BX ;wrzucam cyfre na stos
               inc CX ;licze ile mam elementow na stosie
               jmp RenderDWORD_loop

     RenderDWORD_end:

     Stack_loop:
          pop AX ;pobieram element ze stosu
          add AL, '0' ;dodaje '0' zeby miec cyfre w ascii
          mov ES:[DI], AL ;zapisuje znak do bufora
          inc DI ;przesuwam sie wskaznikiem w buforze
     loop Stack_loop

     @@end:

    mov AL, 10 ;dodaje do bufora przejscie do nowej lini
    mov ES:[DI], AL
    inc DI

  ret
RenderDWORD endp

;Dzieli liczbe znajdujaca sie w DX:AX, zwraca reszte w BX
DivBy10 proc
     push CX

     mov BX, 10 ;dzielimy przez 10
     push AX
     mov AX, DX ;najpierw dzielimy bardziej znaczaca czesc slowa
     xor DX, DX
     div BX ;dzielimy czesc pochodzaca z DX
     mov CX, AX ;zapisujemy wynik dzielenia
     pop AX ;pobieramy mlodsza czesc slowa
     div BX ;dzielimy mlodsza czesc slowa
     mov BX, DX ;zapamietujemy reszte
     mov DX, CX ;zapisujemy starsza podzielona czesc slowa
     
     pop CX
     ret
DivBy10 endp 


;Liczy rozmiar stringa w DS:[SI]
;przechodzi string az znajdzie znak konca stringu
SizeOfaBuffer proc
    push SI
    push AX

    xor CX, CX
    Size_loop:
        xor AX, AX
        mov AL, byte ptr DS:[SI] ;pobieram znak
        cmp AL, 0 ;sprawdzamy znak konca ?
        je Size_end ;jesli tak to koniec, w CX mamy rozmiar 
        inc SI ;jezeli nie to przesuwamy sie dalej
        inc CX
    jmp Size_loop
    Size_end:

    pop AX
    pop SI
    ret
SizeOfaBuffer endp

SaveBuffer proc
    mov AH, 40h ; Funkcja zapisuje dane do pliku
    mov BX, DS:[FILE_HANDLE] ; Do BX podaje uchwyt pliku do ktorego zapisujemy
    lea SI, DS:[BUFFER] ;Wskaznik na buffer z ktorego zapisujemy potrzebny do policzenia rozmairu
    call SizeOfaBuffer ; W CX mamy ilosc bajtow do zapisania
    lea DX, DS:[BUFFER]; W DX mamy wskaznik na buffer dla funkcji 40h
    int 21h

     jc @@Save_error ;jezeli udalo sie zapisac to konczymy
        ret
        
    @@Save_error: ;jezeli nie udalo sie zapisac
          lea DX, DS:[SaveBuffer_error] ;wypisujemy error
          mov AH, 9
          int 21h
          jmp KONIECPROGRAMU
SaveBuffer endp

;funkcja zamykajaca otwarty plik
CloseFile proc
    mov BX, DS:[FILE_HANDLE]
    mov AH, 3Eh
    int 21h 
    jc @@CloseFile_error ;jezeli udalo sie zamknac plik to koniec
        ret
    @@CloseFile_error: ;jezeli nie to wypisujemy info. o bledzie
        lea DX, DS:[CloseFile_error]
        jmp KONIECPROGRAMU
CloseFile endp

code ends

stack segment stack ;segment stosu
                dw  20 dup(?) 
stack_pointer   dw  ? ;wskaznik na stos
stack ends

end start