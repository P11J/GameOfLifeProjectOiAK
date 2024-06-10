%macro print 2
	mov eax, sys_write		; Ustawiamy rejestr eax na wartość 1, co oznacza wywołanie systemowe do zapisu (sys_write)
	mov edi, 1 			; Ustawiamy rejestr edi na 1, co oznacza, że chcemy pisać do standardowego wyjścia (stdout)
	mov rsi, %1			; Ustawiamy rejestr rsi na adres danych, które chcemy wyświetlić (pierwszy argument makra)
	mov edx, %2			; Ustawiamy rejestr edx na długość danych, które chcemy wyświetlić (drugi argument makra)
	syscall				; Wywołujemy systemowe wywołanie, które realizuje operację zapisu na standardowe wyjście
%endmacro

global _start

section .data

	row_cells:	equ 32		; Definiujemy stałą row_cells, która określa liczbę komórek w jednym wierszu, ustawiając ją na 32
	column_cells: 	equ 128 	; Definiujemy stałą column_cells, która określa liczbę komórek w jednej kolumnie, ustawiając ją na 128
	array_length:	equ row_cells * column_cells + row_cells ; Obliczamy całkowitą długość tablicy komórek jako iloczyn liczby wierszy i kolumn, dodając jedną komórkę na nową linię po każdym wierszu

	cells1: 	times array_length db new_line	; Tworzymy tablicę cells1 o długości array_length, wypełniając ją znakami nowej linii
	cells2:		times array_length db new_line	; Tworzymy drugą tablicę cells2 o długości array_length, wypełniając ją znakami nowej linii

	live:		equ 111		; Definiujemy wartość ASCII 111 dla żywej komórki (może być dowolną nieparzystą liczbą)
	dead:		equ 32		; Definiujemy wartość ASCII 32 dla martwej komórki (może być dowolną parzystą liczbą)
	new_line:	equ 10		; Definiujemy wartość ASCII 10 dla znaku nowej linii

	timespec:
    		tv_sec  dq 0		; Ustawiamy zmienną tv_sec na 0, co oznacza, że czas snu będzie równy 0 sekund
    		tv_nsec dq 200000000	; Ustawiamy zmienną tv_nsec na 200000000, co oznacza, że czas snu będzie równy 200 milionom nanosekund (0.2 sekundy)

	clear:		db 27, "[2J", 27, "[H"	; Definiujemy sekwencję znaków do czyszczenia ekranu terminala
	clear_length:	equ $-clear		; Obliczamy długość sekwencji do czyszczenia ekranu

	sys_write:	equ 1		; Definiujemy numer wywołania systemowego do zapisu danych
	sys_nanosleep:	equ 35		; Definiujemy numer wywołania systemowego do usypiania na określony czas
	sys_time:	equ 201		; Definiujemy numer wywołania systemowego do pobrania aktualnego czasu

section .text

_start:

	print clear, clear_length	; Czyścimy ekran terminala, wywołując makro print z argumentami clear i clear_length
	call first_generation		; Wywołujemy funkcję first_generation, która inicjalizuje pierwszą generację komórek
	mov r9, cells1			; Ustawiamy rejestr r9 na adres tablicy cells1
	mov r8, cells2			; Ustawiamy rejestr r8 na adres tablicy cells2

	.generate_cells:
		xchg r8, r9		; Zamieniamy zawartość rejestrów r8 i r9, co oznacza zamianę miejscami tablic cells1 i cells2
		print r8, array_length	; Wyświetlamy aktualną generację komórek, wywołując makro print z tablicą r8 i jej długością array_length
		mov eax, sys_nanosleep	; Ustawiamy rejestr eax na wartość sys_nanosleep, aby usypiać program na określony czas
		mov rdi, timespec	; Ustawiamy rejestr rdi na adres struktury timespec, która określa czas snu
		xor esi, esi		; Zerujemy rejestr esi, aby ignorować pozostały czas w przypadku przerwania snu
		syscall			; Wywołujemy systemowe wywołanie do uśpienia programu na określony czas
		print clear, clear_length	; Ponownie czyścimy ekran terminala
		jmp next_generation	; Przechodzimy do etykiety next_generation, aby wygenerować następną generację komórek

; r8: obecna generacja, r9: następna generacja
next_generation:

	xor ebx, ebx	; Zerujemy rejestr ebx, który będzie służył jako licznik indeksów tablicy
	.process_cell:
		cmp byte [r8 + rbx], new_line	; Porównujemy wartość w tablicy r8 na pozycji rbx z wartością nowej linii
		je .next_cell	; Jeśli napotkamy znak nowej linii, przechodzimy do etykiety .next_cell
		xor eax, eax 	; Zerujemy rejestr eax, który będzie służył jako licznik żywych sąsiadów
		.lower_index_neighbours:
			mov rdx, rbx 	; Kopiujemy wartość licznika rbx do rdx, aby wskazać na pozycje sąsiadów
			dec rdx		; Przesuwamy się do lewego środkowego sąsiada
			js .higher_index_neighbours	; Jeśli rdx jest mniejsze od 0, przechodzimy do sąsiadów z wyższymi indeksami
			mov cl, [r8 + rdx]	; Pobieramy wartość sąsiada z tablicy r8 na pozycji rdx
			and cl, 1	; Sprawdzamy, czy komórka jest żywa (1) czy martwa (0)
			add al, cl	; Dodajemy wartość sąsiada do licznika żywych sąsiadów w rejestrze al
			sub rdx, column_cells - 1 	; Przesuwamy się do prawego górnego sąsiada
			js .higher_index_neighbours	; Jeśli rdx jest mniejsze od 0, przechodzimy do sąsiadów z wyższymi indeksami
			mov cl, [r8 + rdx]	; Pobieramy wartość sąsiada z tablicy r8 na pozycji rdx
			and cl, 1	; Sprawdzamy, czy komórka jest żywa (1) czy martwa (0)
			add al, cl	; Dodajemy wartość sąsiada do licznika żywych sąsiadów w rejestrze al
			dec rdx		; Przesuwamy się do środkowego górnego sąsiada
			js .higher_index_neighbours	; Jeśli rdx jest mniejsze od 0, przechodzimy do sąsiadów z wyższymi indeksami
			mov cl, [r8 + rdx]	; Pobieramy wartość sąsiada z tablicy r8 na pozycji rdx
			and cl, 1	; Sprawdzamy, czy komórka jest żywa (1) czy martwa (0)
			add al, cl	; Dodajemy wartość sąsiada do licznika żywych sąsiadów w rejestrze al
			dec rdx		; Przesuwamy się do lewego górnego sąsiada
			js .higher_index_neighbours 	; Jeśli rdx jest mniejsze od 0, przechodzimy do sąsiadów z wyższymi indeksami
			mov cl, [r8 + rdx]	; Pobieramy wartość sąsiada z tablicy r8 na pozycji rdx
			and cl, 1	; Sprawdzamy, czy komórka jest żywa (1) czy martwa (0)
			add al, cl	; Dodajemy wartość sąsiada do licznika żywych sąsiadów w rejestrze al
		.higher_index_neighbours:
			mov rdx, rbx	; Resetujemy wartość rdx do wartości rbx, aby przejść do sąsiadów z wyższymi indeksami
			inc rdx		; Przesuwamy się do prawego środkowego sąsiada
			cmp rdx, array_length - 1	; Sprawdzamy, czy rdx przekroczyło granicę tablicy
			jge .assign_cell	; Jeśli rdx przekroczyło granicę, przechodzimy do etykiety .assign_cell
			mov cl, [r8 + rdx]	; Pobieramy wartość sąsiada z tablicy r8 na pozycji rdx
			and cl, 1	; Sprawdzamy, czy komórka jest żywa (1) czy martwa (0)
			add al, cl	; Dodajemy wartość sąsiada do licznika żywych sąsiadów w rejestrze al
			add rdx, column_cells - 1	; Przesuwamy się do lewego dolnego sąsiada
			cmp rdx, array_length - 1	; Sprawdzamy, czy rdx przekroczyło granicę tablicy
			jge .assign_cell	; Jeśli rdx przekroczyło granicę, przechodzimy do etykiety .assign_cell
			mov cl, [r8 + rdx]	; Pobieramy wartość sąsiada z tablicy r8 na pozycji rdx
			and cl, 1	; Sprawdzamy, czy komórka jest żywa (1) czy martwa (0)
			add al, cl	; Dodajemy wartość sąsiada do licznika żywych sąsiadów w rejestrze al
			inc rdx		; Przesuwamy się do środkowego dolnego sąsiada
			cmp rdx, array_length - 1	; Sprawdzamy, czy rdx przekroczyło granicę tablicy
			jge .assign_cell	; Jeśli rdx przekroczyło granicę, przechodzimy do etykiety .assign_cell
			mov cl, [r8 + rdx]	; Pobieramy wartość sąsiada z tablicy r8 na pozycji rdx
			and cl, 1	; Sprawdzamy, czy komórka jest żywa (1) czy martwa (0)
			add al, cl	; Dodajemy wartość sąsiada do licznika żywych sąsiadów w rejestrze al
			inc rdx		; Przesuwamy się do prawego dolnego sąsiada
			cmp rdx, array_length - 1	; Sprawdzamy, czy rdx przekroczyło granicę tablicy
			jge .assign_cell	; Jeśli rdx przekroczyło granicę, przechodzimy do etykiety .assign_cell
			mov cl, [r8 + rdx]	; Pobieramy wartość sąsiada z tablicy r8 na pozycji rdx
			and cl, 1	; Sprawdzamy, czy komórka jest żywa (1) czy martwa (0)
			add al, cl	; Dodajemy wartość sąsiada do licznika żywych sąsiadów w rejestrze al
		.assign_cell:
			cmp al, 2	; Sprawdzamy, czy liczba żywych sąsiadów jest równa 2
			je .keep_current	; Jeśli liczba żywych sąsiadów jest równa 2, zachowujemy bieżący stan komórki
			mov byte [r9 + rbx], dead	; Jeśli liczba żywych sąsiadów nie jest równa 2, ustawiamy komórkę jako martwą
			cmp al, 3	; Sprawdzamy, czy liczba żywych sąsiadów jest równa 3
			jne .next_cell	; Jeśli liczba żywych sąsiadów nie jest równa 3, przechodzimy do następnej komórki
			mov byte [r9 + rbx], live	; Jeśli liczba żywych sąsiadów jest równa 3, ustawiamy komórkę jako żywą
			jmp .next_cell	; Przechodzimy do następnej komórki
		.keep_current:
			mov cl, [r8 + rbx]	; Pobieramy bieżący stan komórki
			mov [r9 + rbx], cl	; Ustawiamy stan komórki na ten sam w następnej generacji
		.next_cell:
			inc rbx		; Zwiększamy licznik indeksów tablicy o 1
			cmp rbx, array_length	; Sprawdzamy, czy osiągnęliśmy koniec tablicy
			jne .process_cell	; Jeśli nie osiągnęliśmy końca tablicy, przechodzimy do przetwarzania następnej komórki
			jmp _start.generate_cells	; Jeśli osiągnęliśmy koniec tablicy, wracamy do generowania komórek

; Inicjalizacja tablicy cells1 pseudolosowymi wartościami za pomocą algorytmu RNG (generowania liczb pseudolosowych) sekwencji Weyla
first_generation:

	mov eax, sys_time	; Wywołujemy systemowe wywołanie, aby pobrać aktualny czas
	xor edi, edi 	; Zerujemy rejestr edi, który później użyjemy jako licznik indeksów tablicy
	syscall	; Wykonujemy wywołanie systemowe do pobrania czasu
	mov r8w, ax 	; Przechowujemy ziarno (seed) w rejestrze r8w, które musi być nieparzyste
	and ax, 1	; Sprawdzamy, czy wartość jest nieparzysta (1) czy parzysta (0)
	dec ax	; Jeśli wartość jest nieparzysta, zmniejszamy ją o 1, aby uzyskać 0
	sub r8w, ax	; Upewniamy się, że ziarno (seed) jest nieparzyste
	xor cx, cx 	; Zerujemy rejestr cx, który będzie przechowywać liczbę pseudolosową
	xor r9w, r9w 	; Zerujemy rejestr r9w, który będzie przechowywać sekwencję Weyla
	mov rbx, column_cells	; Ustawiamy rejestr rbx na wartość column_cells, co oznacza indeks następnej nowej linii
	.init_cell:		
		mov ax, cx	; Kopiujemy wartość liczby pseudolosowej do rejestru ax
		mul cx 	; Mnożymy liczbę pseudolosową przez samą siebie
		add r9w, r8w 	; Dodajemy sekwencję Weyla do wyniku mnożenia
		add ax, r9w 	; Dodajemy sekwencję Weyla do wyniku mnożenia
		mov al, ah	; Przesuwamy wyższy bajt ax do niższego bajtu
		mov ah, dl	; Przesuwamy niższy bajt dx do wyższego bajtu ax
		mov cx, ax	; Przechowujemy nową liczbę pseudolosową w rejestrze cx
		and rax, 1	; Sprawdzamy, czy wynik jest parzysty (0) czy nieparzysty (1)
		jz .add_dead	; Jeśli wynik jest parzysty, przechodzimy do dodania martwej komórki
		add rax, live - dead - 1	; Jeśli wynik jest nieparzysty, ustawiamy komórkę jako żywą
		.add_dead:
			add rax, dead	; Dodajemy wartość martwej komórki do rax
		mov [cells1 + rdi], al 	; Przechowujemy wynik w tablicy cells1 na pozycji rdi
		inc rdi	; Zwiększamy indeks tablicy o 1
		cmp rdi, rbx	; Sprawdzamy, czy osiągnęliśmy indeks nowej linii
		jne .init_next	; Jeśli nie osiągnęliśmy indeksu nowej linii, przechodzimy do inicjalizacji następnej komórki
		inc rdi	; Zwiększamy indeks tablicy o 1, aby zachować nową linię
		add rbx, column_cells + 1 ; Aktualizujemy indeks następnej nowej linii
		.init_next:			
			cmp rdi, array_length	; Sprawdzamy, czy osiągnęliśmy koniec tablicy
			jne .init_cell	; Jeśli nie osiągnęliśmy końca tablicy, kontynuujemy inicjalizację komórek
			ret	; Kończymy funkcję
