; OSBYTE wrapper for cc65
; Takes arguments from software stack and calls BBC MOS OSBYTE

        .export _osbyte
        .export _read_char_with_timeout
        .export _check_rs423_buffer
        .export _read_rs423_char

        .import popa
        .import popax
        .import return0
        .import return1

        .import OSBYTE

        .importzp tmp1
        .importzp tmp2
        .importzp ptr1

_osbyte:
        ; Get arg2 from A register (already there from cc65 calling convention)
        sta     tmp1
        
        ; Get arg1 from software stack
        jsr     popa            ; Get arg1, returns in A
        tax                     ; Move arg1 to X register
        
        ; Get command from software stack  
        jsr     popa            ; Get command, returns in A

        ; restore tmp1 (arg2) into Y reg
        ldy     tmp1
        
        ; Now we have:
        ; A = command
        ; X = arg1  
        ; Y = arg2
        
        ; Call BBC MOS OSBYTE routine
        jsr     OSBYTE
        
        ; Return (no return value for void function)
        rts

; Read character with timeout
; Returns: A = status (1=success, 0=timeout, -1=error)
; C signature: int read_char_with_timeout(unsigned char *ch, unsigned int timeout_centiseconds)
_read_char_with_timeout:
        ; timeout_centiseconds is already in A/X when function is called
        ; Save timeout to tmp1/tmp2
        sta     tmp1            ; Store low byte of timeout
        stx     tmp2            ; Store high byte of timeout
        
        ; Get character pointer from stack
        jsr     popax           ; Get pointer into A/X
        sta     ptr1            ; Store low byte of pointer
        stx     ptr1+1          ; Store high byte of pointer
        
        ; Move timeout to X/Y for OSBYTE call
        ldx     tmp1            ; X = timeout low byte
        ldy     tmp2            ; Y = timeout high byte
        
        ; Call OSBYTE 129 (osbyte_IN_KEY)
        lda     #129            ; osbyte_IN_KEY
        jsr     OSBYTE
        
        ; Check results:
        ; Y = 0: Character received, X contains the character
        ; Y = 255: Timeout occurred
        ; Y = 27: Escape key pressed
        
        cpy     #0
        beq     success
        
        cpy     #255
        beq     timeout
        
        ; Error case (Y = 27 or other)
        lda     #$FF             ; Return -1 for error
        tax
        rts
        
timeout:
        jmp     return0
        
success:
        ; Store character at pointer
        txa                     ; Move character from X to A
        ldy     #0
        sta     (ptr1),y        ; Store character at *ch

        jmp     return1        

; Check if RS423 buffer has data
; Returns: A = 1 if data available, 0 if not
; C signature: int check_rs423_buffer(void)
_check_rs423_buffer:
        ; Call OSBYTE 128 (osbyte_READ_ADC) with X=254 (RS423 input buffer)
        lda     #128            ; osbyte_READ_ADC
        ldx     #254            ; RS423_INPUT_BUFFER
        ldy     #$FF            ; Y must contain FF
        jsr     OSBYTE

        ; X now contains the number of characters in the buffer
        ; Non-zero means data available
        cpx     #0
        beq     no_data
        jmp     return1
        
no_data:
        jmp     return0

; Read character from RS423 buffer
; Returns: A = 1 if success, 0 if no data
; C signature: int read_rs423_char(unsigned char *ch)
_read_rs423_char:
        ; Character pointer is already in A/X (rightmost argument)
        sta     ptr1            ; Store low byte of pointer
        stx     ptr1+1          ; Store high byte of pointer
        
        ; Call OSBYTE 145 (osbyte_REMOVE_CHAR) with X=1 (RS423)
        lda     #145            ; osbyte_REMOVE_CHAR
        ldx     #1              ; RS423_GET_CHAR
        ldy     #0              ; Y=0
        jsr     OSBYTE
        
        ; Check carry flag - C=0 means character was successfully removed
        bcs     no_char
        
        ; Store character at pointer (character is in Y register)
        tya                     ; Move character from Y to A
        ldy     #0
        sta     (ptr1),y        ; Store character at *ch
        
        jmp     return1
        
no_char:
        jmp     return0
