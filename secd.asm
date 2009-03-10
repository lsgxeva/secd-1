segment .bss
values		resd	65536
flags		resb	16384

E			resd	1
D			resd	1
true		resd	1
false		resd	1
nil			resd	1

segment .text
	extern _exit

_exec:

	; EAX - (S)tack
	; EBX - (E)nvironment
	; ESI - (C)ontrol
	; EDI - (D)ump
	; EDX - (W)orking

%define S ebx
%define C esi
%define ff edi

%macro car 2 
	mov		%1, [dword values + %2 * 4]
	shr		%1, 16
%endmacro

%macro cdr 2
	mov		%1, [dword values + %2 * 4]
	and		%1, 0xffff
%endmacro

%macro carcdr 2
	mov		%2, [dword values + %2 * 4]
	mov		%1, %2
	shr		%1, 16
	and		%2, 0xffff
%endmacro

%macro cdrcar 2
	mov		%2, [dword values + %2 * 4]
	mov		%1, %2
	and		%1, 0xffff
	shr		%2, 16
%endmacro

%macro ivalue 1
	mov		%1, [dword values + %1 * 4]
%endmacro

%macro newcons 1
	mov		%1, ff 
	cdr		ff, ff
%endmacro

%macro cons 2
	shl		%1, 16
	or		%1, %2
	mov		[dword values + ff * 4], %1
	mov		%1, ff
	cdr		ff, ff
%endmacro

%macro number 1
	mov		[dword values + ff * 4], %1
	mov		%1, ff
	cdr		ff, ff
%endmacro

_cycle:
	carcdr	eax, C
	ivalue	eax	
	jmp		[dword _instr + eax * 4]

_instr \
	dd	0, \
		_instr_LD  , _instr_LDC , _instr_LDF , _instr_AP  , _instr_RTN , \
		_instr_DUM , _instr_RAP , _instr_SEL , _instr_JOIN, _instr_CAR , \
		_instr_CDR , _instr_ATOM, _instr_CONS, _instr_EQ  , _instr_ADD , \
		_instr_SUB , _instr_MUL , _instr_DIV , _instr_REM , _instr_LEQ , \
		_instr_STOP
	
_instr_LD:
	mov		eax, [E]	; W <-- E
	mov		edx, C		; EDX <-- car(cdr(C)), C' <-- cdr(cdr(C))

	carcdr	ecx, edx	; ECX <-- car(car(cdr(C))), EDX <-- cdr(car(cdr(C)))
.loop1:					; FOR i = 1 TO car(car(cdr(C)))
		cdr		eax, eax	; W <-- cdr(W)
		loop	.loop1

	car		eax, eax	; W <-- car(W)
	mov		ecx, edx	; ECX <-- cdr(car(cdr(C)))
.loop2:					; FOR i = 1 TO cdr(car(cdr(C)))
		cdr		eax, eax	; W <-- cdr(W)
		loop	.loop2

	car		eax, eax	; W <-- car(W)
	cons	eax, S
	mov		S, eax		; S <-- cons(W, S)
	jmp		_cycle
	
_instr_LDC:
	cdrcar	C, eax
	xchg	S, eax
	cons	S, eax
	jmp		_cycle

_instr_LDF:
	carcdr	eax, C
	cons	eax, [E]
	cons	eax, S
	mov		S, eax
	jmp		_cycle

_instr_AP:
	cons	C, [D]
	mov		eax, [E]
	cons	eax, C		; EAX <-- cons(E, cons(cdr(C), D))
	carcdr	edx, S		; EDX <-- car(S), S' <-- cdr(S)
	carcdr	C, edx		; C' <-- car(car(S)), EDX <-- cdr(car(S))
	carcdr	ecx, S		; ECX <-- car(cdr(S)), S' <-- cdr(cdr(S))
	cons	S, eax
	mov		[D], S		; D' <-- cons(cdr(cdr(S)), cons(e, cons(cdr(c), d)))
	cons	ecx, edx
	mov		[E], ecx	; E' <-- cons(car(cdr(S)), cdr(car(S)))
	mov		S, [nil]	; S' <-- nil
	jmp		_cycle
	
_instr_RTN:
	mov		edx, [D]
	carcdr	eax, edx	; EAX <-- car(D), EDX <-- cdr(D)
	car		S, S
	cons	S, eax		; S' <-- cons(car(S), car(D))
	carcdr	eax, edx	; EAX <-- car(cdr(D)), EDX <-- cdr(cdr(D))
	mov		[E], eax	; E' <-- car(cdr(D))
	car		C, edx		; C' <-- car(cdr(cdr(D))), EDX <-- cdr(cdr(cdr(D)))
	mov		[D], edx	; D' <-- cdr(cdr(cdr(D)))
	jmp		_cycle
	
_instr_DUM:
	mov		eax, [nil]
	cons	eax, [E]
	mov		[E], eax	; E' <-- cons(nil, E)
	jmp		_cycle
	
_instr_RAP:
	cons	C, [D]		; C' <-- cons(cdr(C), D)
	mov		edx, [E]
	carcdr	eax, edx	; EAX <-- car(E), EDX <-- cdr(E)
	cons	eax, C		; EAX <-- cons(cdr(E), cons(cdr(C), D))
	carcdr	edx, S		; EDX <-- car(S), S' <-- cdr(S)
	carcdr	C, edx		; C' <-- car(car(S)), EDX <-- cdr(car(S))
	mov		[E], edx	; E' <-- EDX = cdr(car(S))
	carcdr	ecx, S		; ECX <-- car(cdr(S)), S' <-- cdr(cdr(S))
	cons	S, eax		; D' <-- cons(cdr(cdr(S)),
	mov		[D], S		;             cons(cdr(E), cons(cdr(C), D)))
	
	; car(EDX) <-- ECX, S used as temporary register
	mov		S, [dword values + edx * 4]
	and		S, 0x0000ffff
	shl		ecx, 16
	or		S, ecx
	mov		[dword values + edx * 4], S

	cons	eax, C		; EAX <-- cons(cdr(E)
	
	mov		S, [nil]	; S' <-- nil
	jmp		_cycle

_instr_SEL:
	mov		eax, C
	carcdr	edx, eax	; EDX <-- car(cdr(C))
	carcdr	ecx, eax	; ECX <-- car(cdr(cdr(C)), EAX <-- cdr(cdr(cdr(C)))
	cons	eax, [D]	; D' <-- cons(cdr(cdr(cdr(C))), D)	
	carcdr	eax, S		; EAX <-- car(S), S' <-- cdr(S)
	cmp		eax, [true]
	cmove	C, edx		; IF car(S) == true THEN C' <-- car(cdr(C))
	cmovne	C, ecx		; IF car(S) != true THEN C' <-- car(cdr(cdr(C)))
	jmp		_cycle

_instr_JOIN:
	mov		eax, [D]
	carcdr	C, eax
	mov		[D], eax 
	jmp		_cycle

_instr_CAR:
	cdrcar	eax, S
	car		S, S
	cons	S, eax 
	jmp		_cycle
	
_instr_CDR:
	cdrcar	eax, S
	cdr		S, S
	cons	S, eax
	jmp		_cycle

_instr_ATOM:
	carcdr	eax, S		; EAX <-- car(S), S' <-- cdr(S)
	mov		ecx, eax 
	and		ecx, 0x00000003
	shl		ecx, 1
	shr		eax, 2
	mov		dl, byte [flags + eax]
	shr		dl, cl		; DL <-- flags for EAX = car(S)
	test	dl, 0x03
	cmovnz	eax, [true]		; IF (isnumber OR issymbol) THEN EAX <-- true
	cmovz	eax, [false]	; IF (!isnumber AND !issymbol) THEN EAX <-- false
	cons	eax, S
	mov		S, eax		; S' <-- cons(true/false, cdr(S))
	jmp		_cycle

_instr_CONS:
	cdrcar	edx, S
	carcdr	eax, edx	; EAX = car(cdr(S)), EDX = cdr(cdr(S)), S' = car(S)
	cons	S, eax
	cons	S, edx
	jmp		_cycle
	
_instr_EQ:
	carcdr	eax, S		; EAX <-- car(S), S' <-- cdr(S)

	push	eax
	mov		ecx, eax	
	and		ecx, 0x00000003
	shl		ecx, 1
	shr		eax, 2
	mov		dl, byte [flags + eax]
	shr		dl, cl		; DL <-- flags for car(S)

	carcdr	eax, S		; EAX <-- car(cdr(S)), S' <-- cdr(cdr(S))
	push	eax

	mov		ecx, eax
	and		ecx, 0x00000003
	shl		ecx, 1
	shr		eax, 2
	mov		dh, byte [flags + eax]
	shr		dh, cl		; DH <-- flags for car(cdr(S))
	
	pop		ecx			; ECX <-- car(cdr(S))
	pop		eax			; EAX <-- car(S)

	and		dx, 0x0101
	cmp		dx, 0x0101
	jne		.else
	ivalue	eax
	ivalue	ecx
	cmp		eax, edx
	jne		.else		; IF isatom(car(S)) AND isatom(car(cdr(S))) AND
						;    ivalue(car(S)) == ivalue(car(cdr(S))) THEN ...
		mov		eax, [true]
		jmp		.endif
.else:
		mov		eax, [false]
.endif:
	cons	eax, S
	mov		S, eax		; S' <-- cons(T/F, cdr(cdr(S)))
	jmp		_cycle

_instr_ADD:
	carcdr	edx, S
	carcdr	eax, S		; EAX = car(cdr(S)), EDX = car(S), S' = cdr(cdr(S))
	ivalue	eax
	ivalue	edx
	add		eax, edx
	number	eax
	cons	eax, S
	mov		S, eax
	jmp		_cycle
	
_instr_SUB:
	carcdr	edx, S
	carcdr	eax, S		; EAX = car(cdr(S)), EDX = car(S), S' = cdr(cdr(S))
	ivalue	eax
	ivalue	edx
	sub		eax, edx
	number	eax
	cons	eax, S
	mov		S, eax
	jmp		_cycle

_instr_MUL:
	carcdr	edx, S
	carcdr	eax, S		; EAX = car(cdr(S)), EDX = car(S), S' = cdr(cdr(S))
	ivalue	eax
	ivalue	edx
	imul	edx
	number	eax
	cons	eax, S
	mov		S, eax
	jmp		_cycle

_instr_DIV:
	carcdr	ecx, S
	carcdr	eax, S		; EAX = car(cdr(S)), ECX = car(S), S' = cdr(cdr(S))
	ivalue	eax
	ivalue	ecx
	mov		edx, eax
	sar		edx, 31		; Extend sign of EAX into all bits of EDX
	div		ecx			; Compute EAX <-- EDX:EAX / ECX
	number	eax
	cons	eax, S
	mov		S, eax
	jmp		_cycle

_instr_REM:
	carcdr	ecx, S
	carcdr	eax, S		; EAX = car(cdr(S)), ECX = car(S), S' = cdr(cdr(S))
	ivalue	eax
	ivalue	ecx
	mov		edx, eax
	sar		edx, 31		; Extend sign of EAX into all bits of EDX
	div		ecx			; Compute EDX <-- EDX:EAX % ECX
	number	edx
	cons	edx, S
	mov		S, edx
	jmp		_cycle

_instr_LEQ:
	carcdr	edx, S
	carcdr	eax, S		; EAX = car(cdr(S)), EDX = car(S), S' = cdr(cdr(S))
	ivalue	eax
	ivalue	edx
	cmp		eax, edx
	cmovle	eax, [true]
	cmovnle	eax, [false]
	cons	eax, S
	mov		S, eax
	jmp		_cycle

_instr_STOP:
	call	_exit


