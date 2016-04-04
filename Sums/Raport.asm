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

    call Input

    mov AX, seg stack_pointer ;inicjalizacja stosu
    mov SS, AX          ;Segment Stosu
    lea SP, SS:[stack_pointer]  ;Wskaźnik na wierzchołek stosu  

    call Parser 


    mov AX, seg INPUT_NAME
    mov DS, AX
    mov ES, AX

    lea DX, DS:[INPUT_NAME] ;Laduje do DX nazwe otwieranego pliku
    call OpenFile   
    call Analyse
    call CloseFile   
    

    call NewFile
    call GenerateBuffer
    call SaveBuffer

    call CloseFile
    
    KONIECPROGRAMU:
    mov AX, 4C00h       ;zakoncz program
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
        mov AL, DS:[SI]
        cmp AL, 13 ;Koniec Stringa?
        je @@FileName_end
        cmp AL, 32 ;Kolejna spacja?
        je @@FileName_end
        movsb ;kopiuje znak z DS:[SI] do DS:[DI]
    jmp @@FileName_loop
    @@FileName_end:

    push AX
    mov AL, 0
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
    mov AH, 3Ch
    xor CX, CX
    lea DX, DS:[OUTPUT_NAME] ;Nazwa pliku wyjsiowego
    int 21h
    mov DS:[FILE_HANDLE], AX ;Zapamietuje uchwyt nowego pliku
    jc @@NewFile_error
        ret
    @@NewFile_error:
        lea DX, DS:[NewFile_error]
        mov AH, 9
        int 21h
        jmp KONIECPROGRAMU
NewFile endp

;Read zwraca do AX ilosc zczytanych bajtow       
Read proc
    mov BX, DS:[FILE_HANDLE] ;uchwyt pliku
    lea DX, DS:[BUFFER] ;addres buffora   
    mov AH, 3Fh
    int 21h
    jc @@Read_error
        ret
    @@Read_error:
        lea DX, DS:[Read_error]
        jmp KONIECPROGRAMU
Read endp            
  
Analyse proc
    
    lea SI, DS:[BUFFER] ; Adress buffora
    mov CX, 4096 ;Tyle bajtow bedziemy pobierac
    
    @@Analyse_loop:
        call Read ;wczytaj bajty z pliku   
        
        push CX
        push AX ;?
          mov CX, AX
          call AnalyseBuffer
        pop AX ;?
        pop CX
        
    cmp AX, CX
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
      mov AL, DS:[SI]
      lea DI, DS:[RES_TABLE]
      mov BL, 4
      mul BL
      add DI, AX
              
      add word ptr DS:[DI], 1
      adc word ptr DS:[DI+2], 0
    
      inc SI
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

  ;================================
  ; Tytul
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
  ;================================
  
  ;================================
  ; Nazwa pliku
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
  ;================================

  ;================================
   ;Enter
   mov AL, 10
   mov ES:[DI], AL
   inc DI
  ;================================


  lea SI, DS:[RES_TABLE] ;Tablica z wynikami w dd

  xor AX, AX
  mov AX, 0 ;Przechdze cala tablice RES_TABLE
  GenerateBuffer_loop:
  push AX
    
    ;================================
    ; Zapisz numer bajtu do pliku
      call SaveByteID
    ;================================
    ;================================
    ; Zapisz dwukropek i spacje
      call SaveColon
    ;================================

    push AX
    push DX
        mov AX, DS:[SI]
        mov DX, DS:[SI+2]
        call RenderDWORD
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
  ;inc DI

pop DX
pop AX
pop SI
pop CX

  ret
GenerateBuffer endp

SaveColon proc
  mov ES:[DI], byte ptr ':'
  inc DI
  ret
SaveColon endp

SaveByteID proc
  push AX
  push BX

  mov BL, 100
  div BL
  add AL, '0'
  mov ES:[DI], AL
  inc DI

  mov AL, AH
  cbw
  mov BL, 10
  div BL
  add AL, '0'
  mov ES:[DI], AL
  inc DI

  add AH, '0'
  mov ES:[DI], AH
  inc DI

  pop BX
  pop AX
  ret
SaveByteID endp



RenderDWORD proc
  
  cmp DX, 0
  jne @@not_zero
  cmp AX, 0
  jne @@not_zero

  mov AL, '0'
  mov ES:[DI], AL
  inc DI
  jmp @@end

  @@not_zero:
  xor BX, BX
  xor CX, CX
     RenderDWORD_loop:
          cmp DX, 0
          jne RenderDWORD_work
          cmp AX, 0
          je RenderDWORD_end

          RenderDWORD_work:
               call DivBy10
               push BX
               inc CX
               jmp RenderDWORD_loop

     RenderDWORD_end:

     Stack_loop:
          pop AX
          add AL, '0'
          mov ES:[DI], AL
          inc DI
     loop Stack_loop

     @@end:

    mov AL, 10
    mov ES:[DI], AL
    inc DI

  ret
RenderDWORD endp

DivBy10 proc
     push CX
     mov BX, 10
     push AX
     mov AX, DX
     xor DX, DX
     div BX
     mov CX, AX
     pop AX
     div BX
     mov BX, DX
     mov DX, CX
     pop CX
     ret
DivBy10 endp 


;Liczy rozmiar stringa w DS:[SI]
SizeOfaBuffer proc
    push SI
    push AX

    xor CX, CX
    Size_loop:
        xor AX, AX
        mov AL, byte ptr DS:[SI]
        cmp AL, 0
        je Size_end
        inc SI
        inc CX
    jmp Size_loop
    Size_end:

    pop AX
    pop SI
    ret
SizeOfaBuffer endp

SaveBuffer proc
    mov AH, 40h
    mov BX, DS:[FILE_HANDLE]
    lea SI, DS:[BUFFER]
    call SizeOfaBuffer
    lea DX, DS:[BUFFER]
    int 21h

     jc @@Save_error
        ret
        
    @@Save_error:
          lea DX, DS:[SaveBuffer_error]
          mov AH, 9
          int 21h
          jmp KONIECPROGRAMU
SaveBuffer endp

CloseFile proc
    mov BX, DS:[FILE_HANDLE]
    mov AH, 3Eh
    int 21h 
    jc @@CloseFile_error
        ret
    @@CloseFile_error:
        lea DX, DS:[CloseFile_error]
        jmp KONIECPROGRAMU
CloseFile endp

code ends

stack segment stack
                dw  20 dup(?) 
stack_pointer   dw  ?           
stack ends

end start