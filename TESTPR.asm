.386p

data_seg segment para public 'DATA' use32

GDT	label	byte
			db	8 dup(0)
GDT_DS	db	0FFh,0FFh,0,0,0,10010010b,11001111b,0
GDT_CS16	db	0FFh,0FFh,0,0,0,10011010b,0,0
GDT_CS	db	0FFh,0FFh,0,0,0,10011010b,11001111b,0
GDT_SS	db	0FFh,0FFh,0,0,0,10010010b,11001111b,0
; ᥣ���� TSS ����� 0 (32-���� ᢮����� TSS)
GDT_TSS0	db	067h,0,0,0,0,10001001b,01000000b,0
; ᥣ���� TSS ����� 1 (32-���� ᢮����� TSS)
GDT_TSS1	db	067h,0,0,0,0,10001001b,01000000b,0
gdt_data1 db 0FFh,0FFh,0,0,0,10010010b,11001111b,0
gdt_size = $-GDT
gdtr	dw	gdt_size-1	; ࠧ��� GDT
	dd	?		; ���� GDT
; �ᯮ��㥬� ᥫ�����
data_selector equ 8h
code_selector16 equ 10h
code_selector equ 18h
stack_selector equ 20h
tss0_selector equ 28h
tss1_selector equ 30h
data1_selector equ 38h

TSS_0	db	68h dup(0)
; ᥣ���� TSS_1. � ���� �㤥� �믮������� ��४��祭��, ⠪ �� ���� 
; ���樠����஢��� ��, �� ����� ���ॡ�������:
TSS_1	dd	0,0,0,0,0,0,0,0			; ���, �⥪�, CR3
	dd	offset task_1			; EIP
; ॣ����� ��饣� �����祭��
	dd	0,0,0,0,0,stack_l2,0,0,0B8000h	; (ESP � EDI) 
; ᥣ����� ॣ����� 
	dd	data_selector,code_selector,stack_selector,data1_selector,0,0
	dd	0		; LDTR
	dd	0		; ���� ⠡���� �����-�뢮��
	data_seg ends
	
	
data_seg1 segment para public 'DATA' use32
msg1	db	"Task 1 message!!!$"
msg2 	db	"Task 2 message!!!$"
data_seg1 ends



code_seg16 segment para public 'CODE' use16
assume cs:code_seg16,ds:data_seg,ss:stack_seg
start:
push data_seg
pop ds

mov ax,3
int 10h
		xor	eax,eax
		
	mov	ax,data_seg1
	shl	eax,4
	mov	word ptr gdt_data1+2,ax
	shr	eax,16
	mov	byte ptr gdt_data1+4,al
	
	mov	ax,code_seg16
	shl	eax,4
	mov	word ptr GDT_CS16+2,ax
	shr	eax,16
	mov	byte ptr GDT_CS16+4,al
	
	mov	ax,code_seg
	shl	eax,4
	mov	word ptr GDT_CS+2,ax
	shr	eax,16
	mov	byte ptr GDT_CS+4,al
	
	mov	ax,stack_seg
	shl	eax,4
	mov	word ptr GDT_SS+2,ax
	shr	eax,16
	mov	byte ptr GDT_SS+4,al
; ���᫨�� ������� ���� GDT
	xor	eax,eax
	mov	ax,data_seg
	shl	eax,4
	push	eax
	add	eax,offset GDT
	mov	dword ptr gdtr+2,eax
; ����㧨�� GDT
	lgdt	fword ptr gdtr
; ���᫨�� ������� ���� ᥣ���⮢ TSS ���� ���� �����
	pop	eax
	push	eax
	add	eax,offset TSS_0
	mov	word ptr GDT_TSS0+2,ax
	shr	eax,16
	mov	byte ptr GDT_TSS0+4,al
	pop	eax
	add	eax,offset TSS_1
	mov	word ptr GDT_TSS1+2,ax
	shr	eax,16
	mov	byte ptr GDT_TSS1+4,al
; ������ A20
	mov	al,2
	out	92h,al
; ������� ���뢠���
	cli
; ������� NMI
	in	al,70h
	or	al,80h
	out	70h,al
; ��४������� � PM
	mov	eax,cr0
	or	al,1
	mov	cr0,eax
	
	db	66h
	db	0EAh
	dd	offset PM_MODE
	dw	code_selector
	
	
	RM_MODE:
	
	mov	eax,cr0
	and	al,0FEh
	mov	cr0,eax
; ����� ��।� �।�롮ન � ����㧨�� CS
	db	0EAh
	dw	$+4
	dw	code_seg16
; ����ந�� ᥣ����� ॣ����� ��� ॠ�쭮�� ०���
	mov	ax,data_seg
	mov	ds,ax
	mov	es,ax
	mov	ax,stack_seg
	mov	bx,stack_l
	mov	ss,ax
	mov	sp,bx
; ࠧ���� NMI
	in	al,70h
	and	al,07FH
	out	70h,al
; ࠧ���� ���뢠���
	sti
; �������� �ணࠬ��
	mov	ah,4Ch
	int	21h
	
code_seg16 ends 
	
	
code_seg segment para public 'CODE' use32
assume cs:code_seg
;msg1	db	"Task 1 message!!!dhfghjdfhdfgdfgdfgdfgdfhdfhfghdf$"
;msg2 	db	"Task 2 message!!!$"
PM_MODE:

xor	eax,eax
	mov	ax,data1_selector
	mov	ds,ax
	mov ax,data_selector
	mov	es,ax
	mov	ax,stack_selector
	mov	ebx,stack_l
	mov	ss,ax
	mov	esp,ebx
; ����㧨�� TSS ����� 0 � ॣ���� TR
	mov	ax,tss0_selector
	ltr	ax
	
	xor edx,edx
    xor	eax,eax
	mov	edi,0B8140h	; DS:EDI - ���� ��砫� �࠭�
	mov si,offset msg1
	
	xor edx,edx
	xor eax,eax
task_0:
	mov al,[si]
	mov	byte ptr es:[edi],al
	inc si
	inc di
	inc di
	
	db	0EAh
	dd	0
	dw	tss1_selector
	
	inc dl
	cmp	dl,17
	jb	task_0
	
; ���쭨� ���室 �� TSS ����� 1
; ��� �� 横��
; ���쭨� ���室 �� ��楤��� ��室� � ॠ��� ०��
	db	0EAh
	dd	offset RM_MODE
	dw	code_selector16

; ����� 1
task_1:
	mov si,offset msg2
	loop131:	
	mov al,[si]
	mov	byte ptr es:[edi],al
	inc si
	
	inc di
	inc di
	
	db	0EAh
	dd	0
	dw	tss0_selector
; � �㤥� ��室��� �ࠢ�����, ����� ����� 0 ��筥� �믮����� ���室
; �� ������ 1 �� ��� �����, �஬� ��ࢮ��
	mov	ecx,02000000h	; �������� ��㧠, �������� �� ᪮���
	loop	$		; ������
	jmp loop131
	
code_seg ends

stack_seg segment para stack 'STACK'
stack_start	db	100h dup(?)	; �⥪ ����� 0
stack_l = $-stack_start
stack_task2	db	100h dup(?)	; �⥪ ����� 1
stack_l2 = $-stack_task2
stack_seg ends

end start