;
; strlen-args.asm
; Author: Elliot Bradbury
; Website: www.elliotbradbury.com
;
; Here's how I had to compile this on my x86_64 machine:
; yasm -a x86 -f elf -o strlen-args.o strlen-args.asm
; ld -m elf_i386 -A elf-i386 -s -o strlen-args strlen-args.o
;
; This program demonstrates how to find the length of a C-style, null-terminated string.
; Accessing command line arguments is also covered.
;
; Usage: ./strlen-args some random strings
;

; line feed constant
LF dd 0xa

section .text
    global _start
    global echol
    global strlen

; entry point
_start:
    ; the first thing on the stack is argc (the number of command line arguments)
    ; not needed, so pop it off
    pop ecx
    jmp printargv

; this is the loop that grabs the character pointers from argv and calls echol
printargv:
    ; pop the next pointer
    pop ecx

    ; if pointer == null, exit
    test ecx,ecx
    jz exit

    ; push argument to echol (char pointer) onto stack
    push ecx
    call echol

    ; we're done with that string so pop it
    pop ecx

    ; loop
    jmp printargv

; echo line function
; echol(char *src)
; returns 0
echol:
    ; function entry
    push ebp
    mov ebp,esp

    ; store char pointer value (contents) in ecx
    mov ecx,[ebp+8]

    ; push arguments to strlen
    push ecx
    call strlen

    ; grab string from stack again (ecx may not be preserved from call)
    pop ecx

    ; mov return value of strlen (string length) into edx for upcoming write()
    mov edx,eax

    ; eax - syscall for write()
    ; ebx - 1 (STDOUT)
    ; ecx - string
    ; edx - string length
    mov eax,4
    mov ebx,1

    ; execute syscall
    int 0x80

    ; write() syscall for newline
    mov eax,4
    mov ebx,1
    mov ecx,LF
    mov edx,1
    int 0x80

    ; restore ebp
    pop ebp

    ; set eax to 0 for a return value (why not?)
    xor eax,eax

    ; return
    ret

; string length
; strlen(char *src)
; returns length of src
strlen:
    ; function entry
    push ebp
    mov ebp,esp

    ; preserve edi
    push edi

    ; store first function argument (string) in edi
    mov edi,[ebp+8]

    ; ecx = 0
    xor ecx,ecx

    ; flip all bits of ecx
    ; ecx is now the largest possible integer (when viewed as an unsigned integer)
    not ecx

    ; al = 0
    xor al,al

    ; clear direction flag
    cld

    ; repeat while [edi+ecx] != al
    ; ... search for 0 in string (which indicates the end of the string)
    repne scasb

    ; flip bits
    ; so ecx is now the length of the string + 1 (null is counted)
    not ecx

    ; restore edi
    pop edi

    ; subtract 1 from ecx for null and load into eax for return value
    lea eax,[ecx-1]

    ; restore ebp
    pop ebp

    ; return
    ret

; exit syscall
; exit()
; return nothing!
exit:
    ; eax - exit() syscall
    ; ebx - 0 (success)
    mov eax,1
    xor ebx,ebx
    int 0x80