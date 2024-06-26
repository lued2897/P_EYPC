title "Proyecto: Ponj" ;codigo opcional. Descripcion breve del programa, el texto entrecomillado se imprime como cabecera en cada pagina de codigo
	.model small	;directiva de modelo de memoria, small => 64KB para memoria de programa y 64KB para memoria de datos
	.386			;directiva para indicar version del procesador
	.stack 64 		;Define el tamano del segmento de stack, se mide en bytes
	.data			;Definicion del segmento de datos
;Definición de constantes
;Valor ASCII de caracteres para el marco del programa
marcoEsqInfIzq 		equ 	200d 	;'╚'
marcoEsqInfDer 		equ 	188d	;'╝'
marcoEsqSupDer 		equ 	187d	;'╗'
marcoEsqSupIzq 		equ 	201d 	;'╔'
marcoCruceVerSup	equ		203d	;'╦'
marcoCruceHorDer	equ 	185d 	;'╣'
marcoCruceVerInf	equ		202d	;'╩'
marcoCruceHorIzq	equ 	204d 	;'╠'
marcoCruce 			equ		206d	;'╬'
marcoHor 			equ 	205d 	;'═'
marcoVer 			equ 	186d 	;'║'
;Atributos de color de BIOS
;Valores de color para carácter
cNegro 			equ		00h
cAzul 			equ		01h
cVerde 			equ 	02h
cCyan 			equ 	03h
cRojo 			equ 	04h
cMagenta 		equ		05h
cCafe 			equ 	06h
cGrisClaro		equ		07h
cGrisOscuro		equ		08h
cAzulClaro		equ		09h
cVerdeClaro		equ		0Ah
cCyanClaro		equ		0Bh
cRojoClaro		equ		0Ch
cMagentaClaro	equ		0Dh
cAmarillo 		equ		0Eh
cBlanco 		equ		0Fh
;Valores de color para fondo de carácter
bgNegro 		equ		00h
bgAzul 			equ		10h
bgVerde 		equ 	20h
bgCyan 			equ 	30h
bgRojo 			equ 	40h
bgMagenta 		equ		50h
bgCafe 			equ 	60h
bgGrisClaro		equ		70h
bgGrisOscuro	equ		80h
bgAzulClaro		equ		90h
bgVerdeClaro	equ		0A0h
bgCyanClaro		equ		0B0h
bgRojoClaro		equ		0C0h
bgMagentaClaro	equ		0D0h
bgAmarillo 		equ		0E0h
bgBlanco 		equ		0F0h

;Definicion de variables
titulo 			db 		"PONJ"
player1 		db 		"Player 1"
player2 		db 		"Player 2"
gana			db		"Won!"
empate			db		"DRAW"
p1_score 		db 		0
p2_score		db 		0

;Variable para definir si el jugador 2 se controla por la maquina
AI_Control		db 		1

;variables para guardar la posición del player 1
p1_col			db 		6
p1_ren			db 		14

;variables para guardar la posición del player 2
p2_col 			db 		73
p2_ren 			db 		14

;variables para guardar una posición auxiliar
;sirven como variables globales para algunos procedimientos
col_aux 		db 		0
ren_aux 		db 		0

;Variables para almacenar la posicion de la bola
b_col 			db		40d
b_ren 			db		14d

;Variables para almacenar la velocidad de la bola
v_x				db		1		;velocidad horizontal
v_y				db		1		;Velocidad vertical

;variable que se utiliza como valor 10 auxiliar en divisiones
diez 			dw 		10
aux 			dw		1		;Variable auxiliar para division
aux_division dw 1

;Variables de la posicion de los obstaculos.
obstaculo1_ren db 0
obstaculo2_ren db 0 
obstaculo1_col db 0
obstaculo2_col db 0

;Una variable contador para algunos loops
conta 			db 		0

;Variable para controlar si se ejecuta el segmento "juego"
pausa			db 		1	;1=pausa, 0=continua
fin_del_juego	db 		0

;Variables que sirven de parametros para el procedimiento IMPRIME_BOTON
boton_caracter 	db 		0
boton_renglon 	db 		0
boton_columna 	db 		0
boton_color		db 		0
boton_bg_color	db 		0

;Auxiliar para calculo de coordenadas del mouse
ocho		db 		8
;Cuando el driver del mouse no esta disponible
no_mouse		db 	'No se encuentra driver de mouse. Presione [enter] para salir$'

;Variable para almacenar el tiempo del sistema
prev_time  dw      ?		;tiempo en ticks
prev_time_barra  dw      ?		;tiempo en ticks para la barra

;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;Macros;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;
;clear - Limpia pantalla
clear macro
	mov ax,0003h 	;ah = 00h, selecciona modo video
					;al = 03h. Modo texto, 16 colores
	int 10h		;llama interrupcion 10h con opcion 00h. 
				;Establece modo de video limpiando pantalla
endm

;posiciona_cursor - Cambia la posición del cursor a la especificada con 'renglon' y 'columna' 
posiciona_cursor macro renglon,columna
	mov dh,renglon	;dh = renglon
	mov dl,columna	;dl = columna
	mov bx,0
	mov ax,0200h 	;preparar ax para interrupcion, opcion 02h
	int 10h 		;interrupcion 10h y opcion 02h. Cambia posicion del cursor
endm 

;inicializa_ds_es - Inicializa el valor del registro DS y ES
inicializa_ds_es 	macro
	mov ax,@data
	mov ds,ax
	mov es,ax 		;Este registro se va a usar, junto con BP, para imprimir cadenas utilizando interrupción 10h
endm

;muestra_cursor_mouse - Establece la visibilidad del cursor del mouser
muestra_cursor_mouse	macro
	mov ax,1		;opcion 0001h
	int 33h			;int 33h para manejo del mouse. Opcion AX=0001h
					;Habilita la visibilidad del cursor del mouse en el programa
endm

;oculta_cursor_teclado - Oculta la visibilidad del cursor del teclado
oculta_cursor_teclado	macro
	mov ah,01h 		;Opcion 01h
	mov cx,2607h 	;Parametro necesario para ocultar cursor
	int 10h 		;int 10, opcion 01h. Cambia la visibilidad del cursor del teclado
endm

;apaga_cursor_parpadeo - Deshabilita el parpadeo del cursor cuando se imprimen caracteres con fondo de color
;Habilita 16 colores de fondo
apaga_cursor_parpadeo	macro
	mov ax,1003h 		;Opcion 1003h
	xor bl,bl 			;BL = 0, parámetro para int 10h opción 1003h
  	int 10h 			;int 10, opcion 01h. Cambia la visibilidad del cursor del teclado
endm

;imprime_caracter_color - Imprime un caracter de cierto color en pantalla, especificado por 'caracter', 'color' y 'bg_color'. 
;Los colores disponibles están en la lista a continuacion;
; Colores:
; 0h: Negro
; 1h: Azul
; 2h: Verde
; 3h: Cyan
; 4h: Rojo
; 5h: Magenta
; 6h: Cafe
; 7h: Gris Claro
; 8h: Gris Oscuro
; 9h: Azul Claro
; Ah: Verde Claro
; Bh: Cyan Claro
; Ch: Rojo Claro
; Dh: Magenta Claro
; Eh: Amarillo
; Fh: Blanco
; utiliza int 10h opcion 09h
; 'caracter' - caracter que se va a imprimir
; 'color' - color que tomará el caracter
; 'bg_color' - color de fondo para el carácter en la celda
; Cuando se define el color del carácter, éste se hace en el registro BL:
; La parte baja de BL (los 4 bits menos significativos) define el color del carácter
; La parte alta de BL (los 4 bits más significativos) define el color de fondo "background" del carácter
imprime_caracter_color macro caracter,color,bg_color
	mov ah,09h				;preparar AH para interrupcion, opcion 09h
	mov al,caracter 		;AL = caracter a imprimir
	mov bh,0				;BH = numero de pagina
	mov bl,color 			
	or bl,bg_color 			;BL = color del caracter
							;'color' define los 4 bits menos significativos 
							;'bg_color' define los 4 bits más significativos 
	mov cx,1				;CX = numero de veces que se imprime el caracter
							;CX es un argumento necesario para opcion 09h de int 10h
	int 10h 				;int 10h, AH=09h, imprime el caracter en AL con el color BL
endm

;imprime_caracter_color - Imprime un caracter de cierto color en pantalla, especificado por 'caracter', 'color' y 'bg_color'. 
; utiliza int 10h opcion 09h
; 'cadena' - nombre de la cadena en memoria que se va a imprimir
; 'long_cadena' - longitud (en caracteres) de la cadena a imprimir
; 'color' - color que tomarán los caracteres de la cadena
; 'bg_color' - color de fondo para los caracteres en la cadena
imprime_cadena_color macro cadena,long_cadena,color,bg_color
	mov ah,13h				;preparar AH para interrupcion, opcion 13h
	lea bp,cadena 			;BP como apuntador a la cadena a imprimir
	mov bh,0				;BH = numero de pagina
	mov bl,color 			
	or bl,bg_color 			;BL = color del caracter
							;'color' define los 4 bits menos significativos 
							;'bg_color' define los 4 bits más significativos 
	mov cx,long_cadena		;CX = longitud de la cadena, se tomarán este número de localidades a partir del apuntador a la cadena
	int 10h 				;int 10h, AH=09h, imprime el caracter en AL con el color BL
endm

;lee_mouse - Revisa el estado del mouse
;Devuelve:
;;BX - estado de los botones
;;;Si BX = 0000h, ningun boton presionado
;;;Si BX = 0001h, boton izquierdo presionado
;;;Si BX = 0002h, boton derecho presionado
;;;Si BX = 0003h, boton izquierdo y derecho presionados
; (400,120) => 80x25 =>Columna: 400 x 80 / 640 = 50; Renglon: (120 x 25 / 200) = 15 => 50,15
;;CX - columna en la que se encuentra el mouse en resolucion 640x200 (columnas x renglones)
;;DX - renglon en el que se encuentra el mouse en resolucion 640x200 (columnas x renglones)
lee_mouse	macro
	mov ax,0003h
	int 33h
endm

;comprueba_mouse - Revisa si el driver del mouse existe
comprueba_mouse 	macro
	mov ax,0		;opcion 0
	int 33h			;llama interrupcion 33h para manejo del mouse, devuelve un valor en AX
					;Si AX = 0000h, no existe el driver. Si AX = FFFFh, existe driver
endm
;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;Fin Macros;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;
	.code
inicio:					;etiqueta inicio
	inicializa_ds_es
	comprueba_mouse		;macro para revisar driver de mouse
	xor ax,0FFFFh		;compara el valor de AX con FFFFh, si el resultado es zero, entonces existe el driver de mouse
	jz imprime_ui		;Si existe el driver del mouse, entonces salta a 'imprime_ui'
	;Si no existe el driver del mouse entonces se muestra un mensaje
	lea dx,[no_mouse]
	mov ax,0900h	;opcion 9 para interrupcion 21h
	int 21h			;interrupcion 21h. Imprime cadena.

	jmp teclado		;salta a 'teclado'
imprime_ui:
	mov ah,0				;Inicializa en tiempo
    int 1Ah
    mov prev_time,dx		;Establece el tiempo de inicio para calcular los ticks
	mov prev_time_barra,dx

	clear 					;limpia pantalla
	oculta_cursor_teclado	;oculta cursor del mouse
	apaga_cursor_parpadeo 	;Deshabilita parpadeo del cursor
	call DIBUJA_UI 	;procedimiento que dibuja marco de la interfaz
	muestra_cursor_mouse 	;hace visible el cursor del mouse
;Revisar que el boton izquierdo del mouse no esté presionado
;Si el botón no está suelto, no continúa
mouse_no_clic:
	lee_mouse
	test bx,0001h
	jnz mouse_no_clic
;Lee el mouse y avanza hasta que se haga clic en el boton izquierdo
mouse:
	lee_mouse
	test bx,0001h 		;Para revisar si el boton izquierdo del mouse fue presionado
	;jz mouse 			;Si el boton izquierdo no fue presionado, vuelve a leer el estado del mouse
	jz verifica_pausa

	;Leer la posicion del mouse y hacer la conversion a resolucion
	;80x25 (columnas x renglones) en modo texto
	mov ax,dx 			;Copia DX en AX. DX es un valor entre 0 y 199 (renglon)
	div [ocho] 			;Division de 8 bits
						;divide el valor del renglon en resolucion 640x200 en donde se encuentra el mouse
						;para obtener el valor correspondiente en resolucion 80x25
	xor ah,ah 			;Descartar el residuo de la division anterior
	mov dx,ax 			;Copia AX en DX. AX es un valor entre 0 y 24 (renglon)

	mov ax,cx 			;Copia CX en AX. CX es un valor entre 0 y 639 (columna)
	div [ocho] 			;Division de 8 bits
						;divide el valor de la columna en resolucion 640x200 en donde se encuentra el mouse
						;para obtener el valor correspondiente en resolucion 80x25
	xor ah,ah 			;Descartar el residuo de la division anterior
	mov cx,ax 			;Copia AX en CX. AX es un valor entre 0 y 79 (columna)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Aqui va la lógica de la posicion del mouse;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;Si el mouse fue presionado en el renglon 0
	;se va a revisar si fue dentro del boton [X] o  en el boton CPU
	cmp dx,0
	;je boton_x
	je primer_renglon

	;comparaciones para comprobar si el cursor se encuentra sobre los renglones 1,2 o 3
	cmp dx,1
	;je boton_stop
	je botones

	cmp dx,2
	;je boton_stop
	je botones

	cmp dx,3
	;je boton_stop
	je botones

	jmp mouse_no_clic

	;Compara la posicion del mouse para determinar si se encuentra en el boton de stop o start
botones:
	cmp cx,33
	jbe mouse_no_clic	;antes de stop
	cmp cx,46
	jge mouse_no_clic	;despues de start
	cmp cx,36
	jbe boton_stop		;en stop
	cmp cx,43
	jge boton_pausa		;en start

	jmp mouse_no_clic	;Fuera de los botones
;boton_x:
primer_renglon:
	cmp cx,0			
	jbe mouse_no_clic	;Antes de CPU
	cmp cx,79			
	jge mouse_no_clic	;despues de X
	cmp cx,3
	jbe boton_cpu		;en CPU
	cmp cx,76
	jge boton_x3		;en X
	
	jmp mouse_no_clic	;Fuera del rango

boton_cpu:
	cmp [AI_Control],1	
	je juego_vs_jugador		;Si ai=1 cambia el valor a 0
	mov [AI_Control],1		;Si ai=0 cambia el valor a 1
	jmp mouse_no_clic

juego_vs_jugador:	
	mov [AI_Control],0		;Si ai=1 cambia el valor a 0
	jmp mouse_no_clic

boton_stop:
	;jmp boton_stop1
	cmp [pausa],1			;Verifica el valor de la bandera pausa
	je reiniciar_juego		;Si pausa=1 salta al segmento reiniciar juego, es decir cuando el juego esta pausado y se presiona stop se reinicia el juego y nadie gana
	mov [pausa],1			;Si pausa=0 se cambia el valor a 1
	mov [fin_del_juego],1	;Se pone la bandera fin_del_juego en 1

	call IMPRIME_CUADRO		;Imprime el cuadro que indica el ganador de la partida
	jmp mouse_no_clic

boton_pausa:
	cmp [pausa],0			;Verifica el valor de la bandera pausa
	je pausar_juego			;Si pausa=0 se cambia el valor a 1
	cmp [fin_del_juego],1	;Si la bandera fin_del_juego es 1 se mantiene la pausa, esto para evitar reiniciar un juego terminado
	je mouse_no_clic
	mov [pausa],0			;Si fin_del_juego es 0 se cambia el valor de la bandera

	jmp mouse_no_clic

pausar_juego:
	mov [pausa],1			;Cambia el valor de la bandera pausa a 1
	jmp mouse_no_clic

;boton_pause:
	;jmp boton_pause1

;Lógica para revisar si el mouse fue presionado en [X]
;[X] se encuentra en renglon 0 y entre columnas 76 y 78
boton_x1:
	cmp cx,76
	jge boton_x2
	jmp mouse_no_clic
boton_x2:
	cmp cx,78
	jbe boton_x3
	jmp mouse_no_clic
boton_x3:
	;Se cumplieron todas las condiciones
	jmp salir

; boton_stop1:
; 	cmp cx,34
; 	jge boton_stop2
; 	jmp mouse_no_clic

; boton_stop2:
; 	cmp cx,36
; 	jbe boton_stop3
; 	jmp mouse_no_clic

; boton_stop3:
; 	cmp [pausa],1
; 	je reiniciar_juego
; 	mov [pausa],1

; 	jmp mouse_no_clic
reiniciar_juego:
		;Player1
		call BORRA_CUADRO		;Borra el cuadro que indica el ganador de la partida

		mov al,[p1_col]			
		mov ah,[p1_ren]
		mov [col_aux],al
		mov [ren_aux],ah
		call BORRA_PLAYER		;Borra la barra del jugador 1
		;Player2
		mov al,[p2_col]
		mov ah,[p2_ren]
		mov [col_aux],al
		mov [ren_aux],ah
		call BORRA_PLAYER		;Borra la barra del jugador 2
		;Reiniciar Bola
		mov dx,0
		CALL BORRA_BOLA			;Borra la bola
		call RESET_BOLA			;Reinicia la posicion de la bola
		call IMPRIME_BOLA		;Imprime la bola en la posicion inicial
		;Reiniciar obstaculos
		;Borra obstaculo 1
		mov bh,obstaculo1_ren
		mov bl,obstaculo1_col
		mov ren_aux,bh
		mov col_aux,bl
		call BORRA_OBSTACULO
		inc ren_aux
		call BORRA_OBSTACULO
		inc col_aux
		call BORRA_OBSTACULO
		dec ren_aux
		call BORRA_OBSTACULO

		;Borra obstaculo 2
		mov bh,obstaculo2_ren
		mov bl,obstaculo2_col
		mov ren_aux,bh
		mov col_aux,bl
		call BORRA_OBSTACULO
		inc ren_aux
		call BORRA_OBSTACULO
		inc col_aux
		call BORRA_OBSTACULO
		dec ren_aux
		call BORRA_OBSTACULO

		;Reiniciar los datos.
		call IMPRIME_DATOS_INICIALES

		;Elimina caracteres adicionales del puntaje
		posiciona_cursor 2,5
		imprime_caracter_color 219,cNegro,bgNegro 
		posiciona_cursor 2,77
		imprime_caracter_color 219,cNegro,bgNegro

		mov pausa,1
		mov [fin_del_juego],0
		jmp mouse_no_clic
verifica_pausa:		
	cmp [pausa],1		;Verifica el valor de la bandera pausa, si es 1 se salta el segmento "juego"
	je mouse		
juego:					;Segmento de codigo que contiene la logica del juego (movimiento de barras y bola)
	;---------------------------------------------------------------------------------------------------------------------
	mov al,[p1_col]
	mov ah,[p1_ren]
	mov [col_aux],al
	mov [ren_aux],ah
	call IMPRIME_PLAYER	;imprime jugador 1

	mov al,[p2_col]
	mov ah,[p2_ren]
	mov [col_aux],al
	mov [ren_aux],ah
	call IMPRIME_PLAYER	;imprime jugador 2 

 	mov ah,01h
 	int 16h
 	;Si bandera Z=0, entonces hay algo en el buffer, si Z=1, entonces el buffer esta vacio

	;Compara el caracter en el buffer para determinar que procedimiento ejecutar
	;jz movimiento_bola
	jz verifica_AI
	cmp al,49			;Compara con 1
	jb mueve_2
	cmp al,50			;Compara con 2
	ja mueve_2

 	call MUEVE_BARRA1	;Movimiento de la barra 1
	mov ah,00h ;vacia buffer
 	int 16h

verifica_AI:			;Si la bandera AI es 1 mueve la barra del jugador 2
	cmp [AI_Control],1
	je mueve_2
	jmp movimiento_bola

mueve_2:
	cmp [AI_Control],1
	je control_AI

	;Controlado por el jugador
	mov ah,01h
 	int 16h
 	;Si bandera Z=0, entonces hay algo en el buffer, si Z=1, entonces el buffer esta vacio
 	jz movimiento_bola
	call MUEVE_BARRA2
	mov ah,00h ;vacia buffer
 	int 16h
	jmp movimiento_bola

control_AI:
	mov ah,01h
 	int 16h
	jz continua_AI

	mov ah,00h ;vacia buffer
 	int 16h

	continua_AI:
	call MUEVE_BARRA2

movimiento_bola:
	;Vuelve a imprimir las barras despues de su movimiento
	mov al,[p1_col]
	mov ah,[p1_ren]
	mov [col_aux],al
	mov [ren_aux],ah
	call IMPRIME_PLAYER	;imprime jugador 1

	mov al,[p2_col]
	mov ah,[p2_ren]
	mov [col_aux],al
	mov [ren_aux],ah
	call IMPRIME_PLAYER	;imprime jugador 2

	call MUEVE_BOLA		;Movimiento de la bola
	jmp mouse
	;---------------------------------------------------------------------------------------------------------------------

;Si no se encontró el driver del mouse, muestra un mensaje y el usuario debe salir tecleando [enter]
teclado:
	mov ah,08h
	int 21h
	cmp al,0Dh		;compara la entrada de teclado si fue [enter]
	jnz teclado 	;Sale del ciclo hasta que presiona la tecla [enter]

salir:				;inicia etiqueta salir
	clear 			;limpia pantalla
	mov ax,4C00h	;AH = 4Ch, opción para terminar programa, AL = 0 Exit Code, código devuelto al finalizar el programa
	int 21h			;señal 21h de interrupción, pasa el control al sistema operativo

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;PROCEDIMIENTOS;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	DIBUJA_UI proc
		;imprimir esquina superior izquierda del marco
		posiciona_cursor 0,0
		imprime_caracter_color marcoEsqSupIzq,cAmarillo,bgNegro
		
		;imprimir esquina superior derecha del marco
		posiciona_cursor 0,79
		imprime_caracter_color marcoEsqSupDer,cAmarillo,bgNegro
		
		;imprimir esquina inferior izquierda del marco
		posiciona_cursor 24,0
		imprime_caracter_color marcoEsqInfIzq,cAmarillo,bgNegro
		
		;imprimir esquina inferior derecha del marco
		posiciona_cursor 24,79
		imprime_caracter_color marcoEsqInfDer,cAmarillo,bgNegro
		
		;imprimir marcos horizontales, superior e inferior
		mov cx,78 		;CX = 004Eh => CH = 00h, CL = 4Eh 
	marcos_horizontales:
		mov [col_aux],cl
		;Superior
		posiciona_cursor 0,[col_aux]
		imprime_caracter_color marcoHor,cAmarillo,bgNegro
		;Inferior
		posiciona_cursor 24,[col_aux]
		imprime_caracter_color marcoHor,cAmarillo,bgNegro
		;Limite mouse
		posiciona_cursor 4,[col_aux]
		imprime_caracter_color marcoHor,cAmarillo,bgNegro
		mov cl,[col_aux]
		loop marcos_horizontales

		;imprimir marcos verticales, derecho e izquierdo
		mov cx,23 		;CX = 0017h => CH = 00h, CL = 17h 
	marcos_verticales:
		mov [ren_aux],cl
		;Izquierdo
		posiciona_cursor [ren_aux],0
		imprime_caracter_color marcoVer,cAmarillo,bgNegro
		;Inferior
		posiciona_cursor [ren_aux],79
		imprime_caracter_color marcoVer,cAmarillo,bgNegro
		mov cl,[ren_aux]
		loop marcos_verticales

		;imprimir marcos verticales internos
		mov cx,3 		;CX = 0003h => CH = 00h, CL = 03h 
	marcos_verticales_internos:
		mov [ren_aux],cl
		;Interno izquierdo (marcador player 1)
		posiciona_cursor [ren_aux],7
		imprime_caracter_color marcoVer,cAmarillo,bgNegro

		;Interno derecho (marcador player 2)
		posiciona_cursor [ren_aux],72
		imprime_caracter_color marcoVer,cAmarillo,bgNegro

		jmp marcos_verticales_internos_aux1
	marcos_verticales_internos_aux2:
		jmp marcos_verticales_internos
	marcos_verticales_internos_aux1:
		;Interno central izquierdo (Timer)
		posiciona_cursor [ren_aux],32
		imprime_caracter_color marcoVer,cAmarillo,bgNegro

		;Interno central derecho (Timer)
		posiciona_cursor [ren_aux],47
		imprime_caracter_color marcoVer,cAmarillo,bgNegro

		mov cl,[ren_aux]
		loop marcos_verticales_internos_aux2

		;imprime intersecciones internas	
		posiciona_cursor 0,7
		imprime_caracter_color marcoCruceVerSup,cAmarillo,bgNegro
		posiciona_cursor 4,7
		imprime_caracter_color marcoCruceVerInf,cAmarillo,bgNegro

		posiciona_cursor 0,32
		imprime_caracter_color marcoCruceVerSup,cAmarillo,bgNegro
		posiciona_cursor 4,32
		imprime_caracter_color marcoCruceVerInf,cAmarillo,bgNegro

		posiciona_cursor 0,47
		imprime_caracter_color marcoCruceVerSup,cAmarillo,bgNegro
		posiciona_cursor 4,47
		imprime_caracter_color marcoCruceVerInf,cAmarillo,bgNegro

		posiciona_cursor 0,72
		imprime_caracter_color marcoCruceVerSup,cAmarillo,bgNegro
		posiciona_cursor 4,72
		imprime_caracter_color marcoCruceVerInf,cAmarillo,bgNegro

		posiciona_cursor 4,0
		imprime_caracter_color marcoCruceHorIzq,cAmarillo,bgNegro
		posiciona_cursor 4,79
		imprime_caracter_color marcoCruceHorDer,cAmarillo,bgNegro

		;imprimir [X] para cerrar programa
		posiciona_cursor 0,76
		imprime_caracter_color '[',cAmarillo,bgNegro
		posiciona_cursor 0,77
		imprime_caracter_color 'X',cRojoClaro,bgNegro
		posiciona_cursor 0,78
		imprime_caracter_color ']',cAmarillo,bgNegro

		;imprimir título
		posiciona_cursor 0,38
		imprime_cadena_color [titulo],4,cBlanco,bgNegro

		call IMPRIME_DATOS_INICIALES
		
		;Imprime el boton CPU
		posiciona_cursor 0,1
		imprime_caracter_color 67,cRojoClaro,bgNegro	;C
		posiciona_cursor 0,2
		imprime_caracter_color 80,cRojoClaro,bgNegro	;P
		posiciona_cursor 0,3
		imprime_caracter_color 85,cRojoClaro,bgNegro	;U

		ret
	endp


	IMPRIME_DATOS_INICIALES proc
		mov [p1_score],0 			;inicializa el score del player 1
		mov [p2_score],0 			;inicializa el score del player 2

		;Imprime el score del player 1, en la posición del col_aux
		;la posición de ren_aux está fija en IMPRIME_SCORE_BL
		mov [col_aux],4
		mov bl,[p1_score]
		call IMPRIME_SCORE_BL

		;Imprime el score del player 1, en la posición del col_aux
		;la posición de ren_aux está fija en IMPRIME_SCORE_BL
		mov [col_aux],76
		mov bl,[p2_score]
		call IMPRIME_SCORE_BL

		;imprime cadena 'Player 1'
		posiciona_cursor 2,9
		imprime_cadena_color player1,8,cBlanco,bgNegro
		
		;imprime cadena 'Player 2'
		posiciona_cursor 2,63
		imprime_cadena_color player2,8,cBlanco,bgNegro

        ;imprime obstaculos generados aleatoriamente

        ;call IMPRIME_OBSTACULO
		call IMPRIME_OBSTACULOS

		;imprime players
		;player 1
		;columna: p1_col, renglón: p1_ren
		mov al,[p1_col]
		mov ah,[p1_ren]
		mov [col_aux],al
		mov [ren_aux],ah
		call IMPRIME_PLAYER

		;player 2
		;columna: p2_col, renglón: p2_ren
		mov al,[p2_col]
		mov ah,[p2_ren]
		mov [col_aux],al
		mov [ren_aux],ah
		call IMPRIME_PLAYER

		;imprime bola
		;columna: 40, renglón: 14
		mov [col_aux],40
		mov [ren_aux],14
		call IMPRIME_BOLA

		;Botón Stop
		mov [boton_caracter],254d
		mov [boton_color],bgAmarillo
		mov [boton_renglon],1
		mov [boton_columna],34
		call IMPRIME_BOTON

		;Botón Start
		mov [boton_caracter],16d
		mov [boton_color],bgAmarillo
		mov [boton_renglon],1
		mov [boton_columna],43d
		call IMPRIME_BOTON

		ret
	endp

	;procedimiento IMPRIME_SCORE_BL
	;Imprime el marcador de un jugador, poniendo la posición
	;en renglón: 2, columna: col_aux
	;El valor que imprime es el que se encuentre en el registro BL
	;Obtiene cada caracter haciendo divisiones entre 10 y metiéndolos en
	;la pila
	IMPRIME_SCORE_BL proc
		xor ah,ah
		mov al,bl
		mov [conta],0
	div10:
		xor dx,dx
		div [diez]
		push dx
		inc [conta]
		cmp ax,0
		ja div10
	imprime_digito:
		posiciona_cursor 2,[col_aux]
		pop dx
		or dl,30h
		imprime_caracter_color dl,cBlanco,bgNegro
		inc [col_aux]
		dec [conta]
		cmp [conta],0
		ja imprime_digito

		ret
	endp

	;procedimiento IMPRIME_PLAYER
	;Imprime la barra que corresponde a un jugador tomando como referencia la posición indicada por las variables
	;ren_aux y col_aux, donde esa posición es el centro del jugador
	;Se imprime el carácter █ en color blanco en cinco renglones
	IMPRIME_PLAYER proc
		posiciona_cursor [ren_aux],[col_aux]
		imprime_caracter_color 219d,cBlanco,bgNegro
		dec [ren_aux]
		posiciona_cursor [ren_aux],[col_aux]
		imprime_caracter_color 219d,cBlanco,bgNegro
		dec [ren_aux]
		posiciona_cursor [ren_aux],[col_aux]
		imprime_caracter_color 219d,cBlanco,bgNegro
		add [ren_aux],3
		posiciona_cursor [ren_aux],[col_aux]
		imprime_caracter_color 219d,cBlanco,bgNegro
		inc [ren_aux]
		posiciona_cursor [ren_aux],[col_aux]
		imprime_caracter_color 219d,cBlanco,bgNegro
		ret
	endp

	BORRA_PLAYER proc
		posiciona_cursor [ren_aux],[col_aux]
		imprime_caracter_color 219d,bgNegro,bgNegro
		dec [ren_aux]
		posiciona_cursor [ren_aux],[col_aux]
		imprime_caracter_color 219d,bgNegro,bgNegro
		dec [ren_aux]
		posiciona_cursor [ren_aux],[col_aux]
		imprime_caracter_color 219d,bgNegro,bgNegro
		add [ren_aux],3
		posiciona_cursor [ren_aux],[col_aux]
		imprime_caracter_color 219d,bgNegro,bgNegro
		inc [ren_aux]
		posiciona_cursor [ren_aux],[col_aux]
		imprime_caracter_color 219d,bgNegro,bgNegro
		ret
	endp

	;procedimiento IMPRIME_BOLA
	;Imprime el carácter ☻ (02h en ASCII) en la posición indicada por 
	;las variables globales
	;ren_aux y col_aux
	IMPRIME_BOLA proc
		;posiciona_cursor [ren_aux],[col_aux]
		posiciona_cursor [b_ren],[b_col]
		imprime_caracter_color 2d,cCyanClaro,bgNegro 
		ret
	endp


	BORRA_BOLA proc
		posiciona_cursor [b_ren],[b_col]
		imprime_caracter_color 219d,bgNegro,bgNegro 
		ret
	endp

	;procedimiento IMPRIME_BOTON
	;Dibuja un boton que abarca 3 renglones y 3 columnas
	;con un caracter centrado dentro del boton
	;en la posición que se especifique (esquina superior izquierda)
	;y de un color especificado
	;Utiliza paso de parametros por variables globales
	;Las variables utilizadas son:
	;boton_caracter: debe contener el caracter que va a mostrar el boton
	;boton_renglon: contiene la posicion del renglon en donde inicia el boton
	;boton_columna: contiene la posicion de la columna en donde inicia el boton
	;boton_color: contiene el color del boton
	IMPRIME_BOTON proc
	 	;La esquina superior izquierda se define en registro CX y define el inicio del botón
		;La esquina inferior derecha se define en registro DX y define el final del botón
		;utilizando opción 06h de int 10h
		;el color del botón se define en BH
		mov ax,0600h 			;AH=06h (scroll up window) AL=00h (borrar)
		mov bh,cRojo	 		;Caracteres en color rojo dentro del botón, los 4 bits menos significativos de BH
		xor bh,[boton_color] 	;Color de fondo en los 4 bits más significativos de BH
		mov ch,[boton_renglon] 	;Renglón de la esquina superior izquierda donde inicia el boton
		mov cl,[boton_columna] 	;Columna de la esquina superior izquierda donde inicia el boton
		mov dh,ch 				;Copia el renglón de la esquina superior izquierda donde inicia el botón
		add dh,2 				;Incrementa el valor copiado por 2, para poner el renglón final
		mov dl,cl 				;Copia la columna de la esquina superior izquierda donde inicia el botón
		add dl,2 				;Incrementa el valor copiado por 2, para poner la columna final
		int 10h
		;se recupera los valores del renglón y columna del botón
		;para posicionar el cursor en el centro e imprimir el 
		;carácter en el centro del botón
		mov [col_aux],dl  				
		mov [ren_aux],dh
		dec [col_aux]
		dec [ren_aux]
		posiciona_cursor [ren_aux],[col_aux]
		imprime_caracter_color [boton_caracter],cRojo,[boton_color]
	 	ret 			;Regreso de llamada a procedimiento
	endp	 			;Indica fin de procedimiento para el ensamblador

    ;procedimiento IMPRIME_OBSTACULO
	;Dibuja un obstaculo en el area de juego
	;Utiliza paso de parametros por variables globales
	;Las variables utilizadas son:
	;col_aux: valor de la columna de la esquina superior izquierda en donde comienza a dibujarse el obstáculo
	;ren_aux: valor del renglon  de la esquina superior izquierda en donde comienza a dibujarse el obstáculo
	IMPRIME_OBSTACULO proc
        ;Posicionar cursor e imprimir un caracter cuyo ASCII es 178d para un obstaculo
        posiciona_cursor [ren_aux],[col_aux]
        imprime_caracter_color 178,cBlanco,cNegro

	 	ret 			;Regreso de llamada a procedimiento
	endp	 			;Indica fin de procedimiento para el ensamblador
	
	BORRA_OBSTACULO proc
        ;Posicionar cursor e imprimir un caracter cuyo ASCII es 178d para un obstaculo
        posiciona_cursor [ren_aux],[col_aux]
        imprime_caracter_color 219,cNegro,cNegro

	 	ret 			;Regreso de llamada a procedimiento
	endp	

	;movimiento de la bola
	;Cambia la direccion de movimiento cuando llega a un borde o cuando choca conun obstaculo o una barra
	MUEVE_BOLA proc		
		mov ah,0
		int 1Ah			;dx=numero de ticks

		mov ax,dx
		sub ax,[prev_time]
		cmp ax,1		;Si ha pasado 1 tick o mas ejecuta el codigo
		jb ret_bola

		mov prev_time,dx	;Guarda el valor obtenido 
		call BORRA_BOLA		;Elimian la bola para evitar que se dibujen rastros

		;Cambio de direccion (bordes)
	Cambia_direccion_borde:
		mov al,b_col			
		cmp al, 78				;limite derecho horizontal
		je	reset_p1			;Reinicia la posicion de la bola al llegar al borde horizontal
		cmp al,1				;Limite izquierdo horizontal
		je	reset_p2			;Reinicia la posicion de la bola al llegar al borde horizontal

		mov al,b_ren
		cmp al,5				;Limite superior horizontal
		je cambia_Y
		cmp al,23				;Limite inferior horizontal
		je cambia_Y

		;Cambio de direccion (barra/obstaculos)
	Cambia_direccion_obs:
		mov cl, b_col
		mov ch, b_ren

		add cl,v_x
		posiciona_cursor [b_ren],cl
		mov ah,08h
		int 10h
		cmp ah,cBlanco
		je cambia_X						;caso 1, la casilla inmediata horizontal es una barra/obstaculo

		add ch,v_y
		posiciona_cursor ch,[b_col]
		mov ah,08h
		int 10h
		cmp ah,cBlanco
		je cambia_Y						;Caso 2, la casilla inmediata vertical es una barra/obstaculo

		posiciona_cursor ch,cl
		mov ah,08h
		int 10h
		cmp ah,cBlanco
		je cambia_XY					;caso 3, La siguiente posicion es una barra/obstaculo

		jmp next_pos

	cambia_X:			;Invierte la velocidad horizontal
		neg [v_x]
		jmp next_pos
	cambia_Y:			;Invierte la velocidad vertical
		neg [v_y]
		cmp al,5				;Limite superior horizontal
		je Cambia_direccion_obs
		cmp al,23
		jmp Cambia_direccion_obs
	cambia_XY:			;Invierte la velocidad
		neg [v_x]
		neg [v_y]

		mov al,b_ren
		cmp al,5				;Limite superior horizontal
		je Cambia_direccion_borde
		cmp al,23				;Limite inferior horizontal
		je Cambia_direccion_borde

		jmp next_pos

	reset_p1:				;Si la bola alcanzo la orilla derecha incrementa el puntaje de jugador 1	
		mov dx,1
		call RESET_BOLA		;Reinicia la posicion de la bola
		call IMPRIME_BOLA	;Imprime la bola
		
		cmp p1_score,10		
		jae termina_juego	;Si el jugador alcanzo diez puntos termina el juego

		jmp ret_bola
	reset_p2:				;Si la bola alcanzo la orilla izquierda incrementa el puntaje de jugador 2
		mov dx,2
		call RESET_BOLA		;Reinicia la posicion de la bola
		call IMPRIME_BOLA	;Imprime la bola

		cmp p2_score,10
		jae termina_juego	;Si el jugador alcanzo diez puntos termina el juego

		jmp ret_bola

	termina_juego:				;Si se alcanzaron diez puntos termina el juego
		mov [pausa],1			;Activa la bandera pausa
		mov [fin_del_juego],1	;Activa la bandera fin del juego
		call IMPRIME_CUADRO		;Imprime el ganador del juego
		jmp ret_bola

	next_pos:					;Calcula la proxima posicion de la pelota
		mov al, v_x				
		mov ah, v_y
		add [b_col],al
		add [b_ren],ah
		call IMPRIME_BOLA

	ret_bola:
		ret
	endp

	RESET_BOLA proc ;recibe dx, dx=1 jugador 1, dx=2 jugador 2
		cmp dx,1
		je punto_p1
		cmp dx,2
		je punto_p2	
		jmp ret_reset_bola
	punto_p1:					;Aumenta el puntaje del jugador 1
		inc [p1_score]
		mov [col_aux],4
		mov bl,[p1_score]
		call IMPRIME_SCORE_BL
		jmp ret_reset_bola
	punto_p2:					;Aumenta el puntaje del jugador 2
		inc [p2_score]
		mov [col_aux],76
		mov bl,[p2_score]
		call IMPRIME_SCORE_BL
	ret_reset_bola:
		mov b_col,40			;Reinicia la pelota a su posicion inicial
		mov b_ren,14
		;mov v_x,1
		;mov v_y,1
		mov dx,0
		ret
	endp


	MUEVE_PLAYER proc
		ret
	endp

	MUEVE_BARRA1 proc
		;mov ah,01h
		;int 16h
		;Si bandera Z=0, entonces hay algo en el buffer, si Z=1, entonces el buffer esta vacio
		;jz mueve_barra_ret

		;compara el buffer con 1 para mover la barra a la izquierda
		mov ah,01h
		int 16h
		cmp al,49d		;La tecla 1 (49 en ascii) mueve la barra hacia abajo
		je inc_p1

		;compara el buffer con 2 para mover la barra a la derecha
		mov ah,01h
		int 16h
		cmp al,50d		;La tecla 2 (50 en ascii) mueve la barra hacia arriba
		je dec_p1

		jmp mueve_barra_ret

	dec_p1:						;Decrementa la posicion del jugador 1
		mov bl,[p1_ren]
		cmp bl,7d				;Evita que la barra pase del marco superior		
		jbe mueve_barra_ret
		
		mov al,[p1_col]
		mov ah,[p1_ren]
		mov [col_aux],al
		mov [ren_aux],ah
		call BORRA_PLAYER		;Borra la barra del jugador 1
		dec [p1_ren]			;Decrementa la posicion
		jmp	mueve_barra_ret		;Imprime la barra del jugador 1

	inc_p1:						;Incrementa la barra del jugador 1
		mov bl,[p1_ren]
		cmp bl,21d				;Evita que la barra pase del marco inferior
		jae mueve_barra_ret

		mov al,[p1_col]
		mov ah,[p1_ren]
		mov [col_aux],al
		mov [ren_aux],ah
		call BORRA_PLAYER		;Borra la barra del jugador 1
		inc [p1_ren]			;Decrementa la posicion
		jmp	mueve_barra_ret		;Imprime la barra del jugador 1
	
	mueve_barra_ret:
		ret
	endp

	MUEVE_BARRA2 proc
		cmp [AI_Control],1		;Verifica el valro de la bandera AI
		je computadora

		;Logica para el control por un usuario
		;compara el buffer con 9 para mover la barra a la izquierda
		mov ah,01h
		int 16h
		cmp al,57d		;La tecla 9 (49 en ascii) mueve la barra hacia abajo
		je inc_p2

		;compara el buffer con 0 para mover la barra a la derecha
		mov ah,01h
		int 16h
		cmp al,48d		;La tecla 0 (50 en ascii) mueve la barra hacia arriba
		je dec_p2

		jmp mueve_barra2_ret

	dec_p2:						;Decrementa la posicion del jugador 2
		mov bl,[p2_ren]
		cmp bl,7d				;Evita que supere el marco superior
		jbe mueve_barra2_ret
		
		mov al,[p2_col]
		mov ah,[p2_ren]
		mov [col_aux],al
		mov [ren_aux],ah
		call BORRA_PLAYER		;Elimina la barra
		dec [p2_ren]			;Decrementa la posicion
		jmp	mueve_barra2_ret	

	inc_p2:						;Aumenta la posicion del jugador 2
		mov bl,[p2_ren]
		cmp bl,21d				;Evita que supere el marco inferior
		jae mueve_barra2_ret

		mov al,[p2_col]
		mov ah,[p2_ren]
		mov [col_aux],al
		mov [ren_aux],ah
		call BORRA_PLAYER		;Elimina la barra del jugador 2
		inc [p2_ren]			;Aumenta la posicion del jugador 2
		jmp	mueve_barra2_ret

	computadora:				;Logica para que el cpu controle el jua=gador 2

		mov ah,0
		int 1Ah
		mov ax,dx
		sub ax,[prev_time_barra]
		cmp ax,2				;Determina si han pasado mas de dos ticks desde el ultimo movimiento de la barra
		jb mueve_barra2_ret		;Si han pasado menos de dos ticks sale del procedimiento

		mov [prev_time_barra],dx;Guarda el valor obtenido como valor previo
		mov al,[b_ren]
		cmp al,[p2_ren]
		jl dec_p2				;Si la barra esta debajo de la bola mueve la barra hacia arriba
		jmp inc_p2				;Si la barra esta arriba de la bola mueve la barra hacia abajo

	mueve_barra2_ret:
		ret
	endp

	IMPRIME_OBSTACULOS proc 	;Logica para generar aleatoriamente la posicion de ls obstaculos
		mov ah,0				;tiempo del sistema
		int 1Ah					;dx=tiempo
		mov [ren_aux],6			
		mov [col_aux],20		;Posicion base del obstaculo
		mov cx,2				;El loop se ejecuta 2 veces

		lea di,obstaculo1_ren	
		lea si,obstaculo1_col	;Obtiene la posicion del obstaculo 1

		xor di,di				;di=0


	INICIO_OBSTACULOS:
		;20-59
		;cordenada en x del obstaculo
		mov [aux],dx
		mov ax,dx
		mov dx,0
		mov aux_division,39		;39=Rango horizontal disponible
		div aux_division		;Divide el tiempo del sistema entre 39
		add [col_aux],dl		;dl contiene el modulo de la division, este actua como el desplazamiento a la posicion base de la columna

		mov ax,[aux]
		mov dx,0
		mov aux_division,6		;6=Rango vertical disponible
		div aux_division		;Divide el tiempo entre 6
		add [ren_aux],dl		;dl contiene el modulo de la division, este actua como desplazamiento a la posicion base el renglon

		mov bh,ren_aux
		mov [obstaculo1_ren+di],bh	
		mov bh,col_aux
		mov [obstaculo1_col+di],bh	;Asigna al obstaculo la posicion calculada

		push cx						;Almacena el valor de la variable de control del loop
		call IMPRIME_OBSTACULO
		inc [col_aux]
		call IMPRIME_OBSTACULO
		inc [ren_aux]
		call IMPRIME_OBSTACULO
		dec [col_aux]
		call IMPRIME_OBSTACULO		;Imprime los 4 caracteres del obstaculo
		pop cx						;Recupera el valor de la variable de control

		mov [ren_aux],15			;Asigna la posicion base al obstaculo 2
		mov [col_aux],20
		mov dx,[aux]				;Aumenta el valor de dx para garantizar una posicion diferente
		add dx,256

		inc di						;Aumenta di para almacenar la posicion dle proximo obstaculo

		loop INICIO_OBSTACULOS
		
		ret
	endp

	BORRA_CUADRO proc				;Elimina el cuadro que indica el ganador de la partida, imprime caracteres negros sobre  el area del cuadro
		mov cx,16
		loop_limpia_cuadro1:
		mov [col_aux],31
		add [col_aux],cl
		push cx
		posiciona_cursor 10,[col_aux]
		imprime_caracter_color 219,cNegro,bgNegro
		posiciona_cursor 11,[col_aux]
		imprime_caracter_color 219,cNegro,bgNegro
		pop cx
		loop loop_limpia_cuadro1

		mov cx,16
		loop_limpia_cuadro2:
		mov [col_aux],31
		add [col_aux],cl
		push cx
		posiciona_cursor 12,[col_aux]
		imprime_caracter_color 219,cNegro,bgNegro
		posiciona_cursor 13,[col_aux]
		imprime_caracter_color 219,cNegro,bgNegro
		pop cx
		loop loop_limpia_cuadro2

		mov cx,16
		loop_limpia_cuadro3:
		mov [col_aux],31
		add [col_aux],cl
		push cx
		posiciona_cursor 14,[col_aux]
		imprime_caracter_color 219,cNegro,bgNegro
		posiciona_cursor 15,[col_aux]
		imprime_caracter_color 219,cNegro,bgNegro
		pop cx
		loop loop_limpia_cuadro3
		ret
	endp

	IMPRIME_CUADRO proc												;Imprime el cuadro que indica el ganador de la partida
		;Esquinas del cuadro
		posiciona_cursor 10,32
		imprime_caracter_color marcoEsqSupIzq,cAmarillo,bgNegro
		posiciona_cursor 10,47
		imprime_caracter_color marcoEsqSupDer,cAmarillo,bgNegro
		posiciona_cursor 15,32
		imprime_caracter_color marcoEsqInfIzq,cAmarillo,bgNegro
		posiciona_cursor 15,47
		imprime_caracter_color marcoEsqInfDer,cAmarillo,bgNegro

		;Marcos horizontales
		mov cx,14
		loop_cuadro_horizontal:
		mov [col_aux],32
		add [col_aux],cl
		push cx
		posiciona_cursor 15,[col_aux]
		imprime_caracter_color marcoHor,cAmarillo,bgNegro
		posiciona_cursor 10,[col_aux]
		imprime_caracter_color marcoHor,cAmarillo,bgNegro

		pop cx
		loop loop_cuadro_horizontal

		;Limpia el interior del marco
		mov cx,14
		loop_limpia1:
		mov [col_aux],32
		add [col_aux],cl
		push cx
		posiciona_cursor 11,[col_aux]
		imprime_caracter_color 219,cNegro,bgNegro
		posiciona_cursor 12,[col_aux]
		imprime_caracter_color 219,cNegro,bgNegro
		pop cx
		loop loop_limpia1

		mov cx,14
		loop_limpia2:
		mov [col_aux],32
		add [col_aux],cl
		push cx
		posiciona_cursor 13,[col_aux]
		imprime_caracter_color 219,cNegro,bgNegro
		posiciona_cursor 14,[col_aux]
		imprime_caracter_color 219,cNegro,bgNegro
		pop cx
		loop loop_limpia2

		;Imprime los marcos verticales
		mov cx,4
		loop_cuadro_vertical:
		mov [ren_aux],10
		add [ren_aux],cl
		push cx
		posiciona_cursor [ren_aux],32
		imprime_caracter_color marcoVer,cAmarillo,bgNegro
		posiciona_cursor [ren_aux],47
		imprime_caracter_color marcoVer,cAmarillo,bgNegro
		pop cx
		loop loop_cuadro_vertical

		;Determina el ganador de la partida comparando los puntajes
		mov al,[p1_score]
		cmp [p2_score],al	
		ja	imprime_p2		;Si p2_score es mayor el jugador 2 gana
		cmp [p2_score],al
		je imprime_empate	;Si los puntajes son iguales es un empate

		;Gana el jugador 1
		posiciona_cursor 12,36
		imprime_cadena_color player1,8,cBlanco,bgNegro

		posiciona_cursor 13,38
		imprime_cadena_color [gana],4,cBlanco,bgNegro
		jmp ret_imprime_cuadro

	imprime_p2:
		;Gana el jugador 2
		posiciona_cursor 12,36
		imprime_cadena_color player2,8,cBlanco,bgNegro

		posiciona_cursor 13,38
		imprime_cadena_color [gana],4,cBlanco,bgNegro
		jmp ret_imprime_cuadro

	imprime_empate:
		;Empate
		posiciona_cursor 12,38
		imprime_cadena_color [empate],4,cBlanco,bgNegro

	ret_imprime_cuadro:
		ret
	endp
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;FIN PROCEDIMIENTOS;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	end inicio			;fin de etiqueta inicio, fin de programa