.386  ; Директива для использования набора операций процессора 80386
.MODEL FLAT, STDCALL ; Определяем модель памяти
OPTION CASEMAP: NONE
EXTERN  WriteConsoleA@20: PROC
EXTERN  CharToOemA@8: PROC
EXTERN  GetStdHandle@4: PROC
EXTERN  lstrlenA@4: PROC
EXTERN  ExitProcess@4:PROC
EXTERN  ReadConsoleA@20: PROC


.DATA
STR1	DB "Введите 1 число: ", 10, 0
STR2	DB "Введите 2 число: ", 10, 0
STR3	DB "Результат: ", 0
ERROR_STR		DB "Произошла ошибка, введенное число должно быть от 4 до 8 символов!", 0
OVERFLOW		DB "Произошла ошибка переполнения регистра, невозможно определить результат произведения", 0
DOUT	DD ?
DIN		DD ?
LENS	DD ?
NUM1	DD ?
NUM2	DD ?
BUF		DB 20 dup (?)
OS		DD ?
S_16	DD 16
SIGN_FIRST		DB ?
SIGN_SECOND		DB ?
SIGN	DB ?


.CODE
MAIN PROC

; Меняем во всех строках кодировку на 'досовскую'
MOV EAX, OFFSET STR1
PUSH EAX
PUSH EAX
CALL CharToOemA@8

MOV EAX, OFFSET STR2
PUSH EAX
PUSH EAX
CALL CharToOemA@8

MOV EAX, OFFSET STR3
PUSH EAX
PUSH EAX
CALL CharToOemA@8

MOV EAX, OFFSET ERROR_STR
PUSH EAX
PUSH EAX
CALL CharToOemA@8

MOV EAX, OFFSET OVERFLOW
PUSH EAX
PUSH EAX
CALL CharToOemA@8


PUSH -11
CALL GetStdHandle@4
MOV DOUT, EAX

PUSH -10
CALL GetStdHandle@4
MOV DIN, EAX


PUSH OFFSET STR1
CALL lstrlenA@4
PUSH 0
PUSH OFFSET LENS
PUSH EAX
PUSH OFFSET STR1
PUSH DOUT
CALL WriteConsoleA@20 ; "Введите 1 число: "

; считывание первого числа из консоли
PUSH 0
PUSH OFFSET LENS
PUSH 200
PUSH OFFSET BUF
PUSH DIN
CALL ReadConsoleA@20

; Преобразование первого числа из строки символов в число
MOV ESI, OFFSET BUF
DEC LENS
DEC LENS	
MOV ECX, LENS

MOV AL, [ESI]	; Проверяем первое число на отрицательность
CMP AL, '-'
JNE CONTINUE_F	; Если первый символ не -, то продолжаем переводить число из строки

DEC LENS		; Если первый знак -, то уменьшаем длину строки на 1
MOV ECX, LENS
INC ESI			; Перемещаем регистр ESI на 1 вперед (на первую цифру числа)
MOV SIGN_FIRST, 1 ; Меняем знак первого числа на -

CONTINUE_F:		; Продолжаем переводить число
	CMP LENS, 4
	JB ERROR
	CMP LENS, 8
	JA ERROR
	MOV OS, 10
	XOR EAX, EAX
	XOR EBX, EBX
	CONV:
		MOV BL, [ESI]
		SUB BL, 48
		MUL OS
		ADD EAX, EBX
		INC ESI
	LOOP CONV
	MOV NUM1, EAX

PUSH OFFSET STR2
CALL lstrlenA@4
PUSH 0
PUSH OFFSET LENS
PUSH EAX
PUSH OFFSET STR2
PUSH DOUT
CALL WriteConsoleA@20 ; "Введите 2 число: "

; считывание второго числа из консоли
PUSH 0
PUSH OFFSET LENS
PUSH 200
PUSH OFFSET BUF
PUSH DIN
CALL ReadConsoleA@20

; Преобразование второго числа из сторки символов в число
MOV ESI, OFFSET BUF
DEC LENS
DEC LENS
MOV ECX, LENS

MOV AL, [ESI]	; Проверяем второе число на отрицательность
CMP AL, '-'
JNE CONTINUE_S	; Если первый символ числа не минус, то продолжаем конверитровать число
DEC LENS		; Если минус, то уменьшаем длину строки на 1
MOV ECX, LENS
INC ESI			; Сдвигаем регистр ESI на одни (чтобы указывал на число)
MOV SIGN_SECOND, 1 ; меняем знак числа на -

CONTINUE_S:		; Продолжаем переводить число
	CMP LENS, 4
	JB ERROR
	CMP LENS, 8
	JA ERROR
	MOV OS, 10
	XOR AX, AX
	XOR BX, BX
	SONV:
		MOV BL, [ESI]
		SUB BL, 48
		MUL OS
		ADD AX, BX
		INC ESI
	LOOP SONV
	MOV NUM2, EAX


PUSH OFFSET STR3
CALL lstrlenA@4
PUSH 0
PUSH OFFSET LENS
PUSH EAX
PUSH OFFSET STR3
PUSH DOUT
CALL WriteConsoleA@20


; Проверяем какой должен быть знак у результата
CMP SIGN_FIRST, 1
JNE AGAIN
CMP SIGN_SECOND, 0
JNE AGAIN
MOV SIGN, 1

AGAIN:
	CMP SIGN_FIRST, 0
	JNE ALG
	CMP SIGN_SECOND, 1
	JNE ALG
	MOV SIGN, 1

ALG:
	XOR EDX, EDX
	XOR EBX, EBX
	XOR EAX, EAX
	MOV EAX, NUM1
	MOV EBX, NUM2
	MUL EBX				; производим умножение введенных чисел
	JC OVER
	MOV EBX, EAX

MOV ESI, OFFSET BUF
CMP SIGN, 0				; Если результат отрицательный, то добавить в строку знак '-'.
JE FUNC
MOV AX, 45				; 45 - код знака '-'.
MOV [ESI], AX
INC ESI

FUNC:	
	MOV EAX, EBX
	XOR EDX, EDX
	XOR EDI, EDI
	
	CONVERT_FROM10TO16:
		CMP EBX, S_16
		JAE FUNC1
		JB FUNC5
		FUNC1:
			DIV S_16
			ADD DX, '0'
		CMP DX, '9'
		JA FUNC2
		JBE FUNC3
		FUNC2:
			ADD DX, 7
		FUNC3:
			PUSH EDX ; кладем данные в стек, для инвертирования
			ADD EDI, 1
			XOR EDX, EDX
			XOR EBX,EBX
			MOV BX, AX
			MOV ECX, 2
	LOOP CONVERT_FROM10TO16
	FUNC5:
		ADD AX, '0'
		CMP AX, '9'
		JA FUNC6
		JBE FUNC7
		FUNC6:
			ADD AX, 7

	FUNC7:
		PUSH EAX ; кладем данные в стек, для инвертирования
		ADD EDI, 1
		MOV ECX, EDI
		CONVERTS:
			POP [ESI]
			INC ESI
		LOOP CONVERTS

PUSH OFFSET BUF
CALL lstrlenA@4
PUSH 0
PUSH OFFSET LENS
PUSH EAX
PUSH OFFSET BUF
PUSH DOUT
CALL WriteConsoleA@20
PUSH 0
CALL ExitProcess@4

PUSH 0
CALL ExitProcess@4

ERROR:
	PUSH OFFSET ERROR_STR
	CALL lstrlenA@4
	PUSH 0
	PUSH OFFSET LENS
	PUSH EAX
	PUSH OFFSET ERROR_STR
	PUSH DOUT
	CALL WriteConsoleA@20
	PUSH 0
	CALL ExitProcess@4

OVER:
	PUSH OFFSET OVERFLOW
	CALL lstrlenA@4
	PUSH 0
	PUSH OFFSET LENS
	PUSH EAX
	PUSH OFFSET OVERFLOW
	PUSH DOUT
	CALL WriteConsoleA@20
	PUSH 0
	CALL ExitProcess@4

MAIN ENDP
END MAIN
