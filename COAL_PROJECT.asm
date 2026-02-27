; Password Security System - Final Version
; EMU8086 Implementation

.MODEL SMALL
.STACK 100H

.DATA
    ; Password storage
    STORED_PASSWORD DB 'PASS123$'       ; Predefined password
    PASSWORD_LENGTH DW 7                ; Length of password
    
    ; Input buffers
    INPUT_BUFFER DB 20 DUP('$')        ; Buffer for user input
    MENU_CHOICE DB ?                    ; Menu selection
    
    ; Counters and flags
    FAILED_ATTEMPTS DB 0                ; Counter for failed attempts
    TOTAL_ATTEMPTS DB 0                 ; Total login attempts
    MAX_ATTEMPTS DB 3                   ; Maximum allowed attempts
    BRUTEFORCE_FLAG DB 0                ; Flag for brute force detection
    DICTIONARY_FLAG DB 0                ; Flag for dictionary attack
    
    ; Common weak passwords (Dictionary)
    WEAK_PASS1 DB '123456$'
    WEAK_PASS2 DB 'password$'
    WEAK_PASS3 DB 'admin$'
    WEAK_PASS4 DB '12345$'
    WEAK_PASS5 DB 'qwerty$'
    
    ; Menu Messages
    MSG_MAIN_MENU DB 0DH,0AH,'===============================================',0DH,0AH
                  DB '   PASSWORD SECURITY SYSTEM - MAIN MENU',0DH,0AH
                  DB '===============================================',0DH,0AH
                  DB '1. Login with Brute Force Detection',0DH,0AH
                  DB '2. Login with Dictionary Attack Detection',0DH,0AH
                  DB '3. View Security Audit Report',0DH,0AH
                  DB '4. Exit',0DH,0AH
                  DB '===============================================',0DH,0AH
                  DB 'Enter your choice (1-4): $'
    
    ; System Messages
    MSG_PROMPT DB 0DH,0AH,'Enter Password: $'
    MSG_CORRECT DB 0DH,0AH,0AH,'*** ACCESS GRANTED ***',0DH,0AH,'Welcome to the system!',0DH,0AH,'$'
    MSG_INCORRECT DB 0DH,0AH,'[ERROR] Incorrect Password!',0DH,0AH,'$'
    MSG_ATTEMPTS DB 'Attempts remaining: $'
    MSG_LOCKED DB 0DH,0AH,0AH,'*** SYSTEM LOCKED ***',0DH,0AH,'Too many failed attempts!',0DH,0AH,'$'
    
    ; Attack Detection Messages
    MSG_BRUTEFORCE DB 0DH,0AH,'[ALERT] Brute-Force Attack Detected!',0DH,0AH,'Multiple rapid attempts detected.',0DH,0AH,'$'
    MSG_DICTIONARY DB 0DH,0AH,'[ALERT] Dictionary Attack Detected!',0DH,0AH,'Common weak password detected.',0DH,0AH,'$'
    
    ; Audit Messages
    MSG_AUDIT DB 0DH,0AH,0AH,'========== SECURITY AUDIT REPORT ==========',0DH,0AH,'$'
    MSG_TOTAL DB 'Total Login Attempts: $'
    MSG_FAILED DB 0DH,0AH,'Failed Attempts: $'
    MSG_STATUS DB 0DH,0AH,'Current Status: $'
    MSG_SUCCESS_STATUS DB 'Active Session',0DH,0AH,'$'
    MSG_FAILED_STATUS DB 'System Locked',0DH,0AH,'$'
    MSG_NORMAL_STATUS DB 'Ready for Login',0DH,0AH,'$'
    
    MSG_THREATS DB 0DH,0AH,'Detected Threats:',0DH,0AH,'$'
    MSG_BRUTE_THREAT DB '  - Brute Force Attack',0DH,0AH,'$'
    MSG_DICT_THREAT DB '  - Dictionary Attack',0DH,0AH,'$'
    MSG_NO_THREAT DB '  - No threats detected',0DH,0AH,'$'
    
    MSG_HINT DB 0DH,0AH,'[HINT] Correct password is: PASS123',0DH,0AH,'$'
    MSG_PRESS_KEY DB 0DH,0AH,'Press any key to continue...$'
    MSG_INVALID DB 0DH,0AH,'Invalid choice! Please try again.',0DH,0AH,'$'
    MSG_GOODBYE DB 0DH,0AH,'Thank you for using Password Security System!',0DH,0AH,'$'
    NEWLINE DB 0DH,0AH,'$'

.CODE
MAIN PROC
    MOV AX, @DATA
    MOV DS, AX
    
MAIN_MENU_LOOP:
    ; Clear screen (print newlines)
    MOV CX, 2
CLEAR_SCREEN:
    LEA DX, NEWLINE
    MOV AH, 09H
    INT 21H
    LOOP CLEAR_SCREEN
    
    ; Display main menu
    LEA DX, MSG_MAIN_MENU
    MOV AH, 09H
    INT 21H
    
    ; Get menu choice
    MOV AH, 01H
    INT 21H
    MOV MENU_CHOICE, AL
    
    ; Process menu choice
    CMP AL, '1'
    JE OPTION_1
    CMP AL, '2'
    JE OPTION_2
    CMP AL, '3'
    JE OPTION_3
    CMP AL, '4'
    JE EXIT_PROGRAM
    
    ; Invalid choice
    LEA DX, MSG_INVALID
    MOV AH, 09H
    INT 21H
    CALL PAUSE
    JMP MAIN_MENU_LOOP

OPTION_1:
    ; Login with Brute Force Detection
    CALL RESET_FLAGS
    CALL LOGIN_BRUTEFORCE_MODE
    CALL PAUSE
    JMP MAIN_MENU_LOOP

OPTION_2:
    ; Login with Dictionary Attack Detection
    CALL RESET_FLAGS
    CALL LOGIN_DICTIONARY_MODE
    CALL PAUSE
    JMP MAIN_MENU_LOOP

OPTION_3:
    ; View Audit Report
    CALL DISPLAY_AUDIT
    CALL PAUSE
    JMP MAIN_MENU_LOOP

EXIT_PROGRAM:
    ; Display final audit
    CALL DISPLAY_AUDIT
    
    LEA DX, NEWLINE
    MOV AH, 09H
    INT 21H
    
    LEA DX, MSG_GOODBYE
    MOV AH, 09H
    INT 21H
    
    ; Exit program
    MOV AH, 4CH
    INT 21H

MAIN ENDP

; ============ RESET FLAGS PROCEDURE ============
RESET_FLAGS PROC
    MOV FAILED_ATTEMPTS, 0
    MOV TOTAL_ATTEMPTS, 0
    RET
RESET_FLAGS ENDP

; ============ LOGIN WITH BRUTE FORCE DETECTION ============
LOGIN_BRUTEFORCE_MODE PROC
    PUSH AX
    
    LEA DX, NEWLINE
    MOV AH, 09H
    INT 21H
    
    LEA DX, MSG_HINT
    MOV AH, 09H
    INT 21H

LBF_LOOP:
    CMP FAILED_ATTEMPTS, 3
    JGE LBF_LOCKED
    
    INC TOTAL_ATTEMPTS
    
    LEA DX, MSG_PROMPT
    MOV AH, 09H
    INT 21H
    
    CALL GET_PASSWORD
    CALL COMPARE_PASSWORDS
    
    CMP AL, 1
    JE LBF_SUCCESS
    
    INC FAILED_ATTEMPTS
    LEA DX, MSG_INCORRECT
    MOV AH, 09H
    INT 21H
    
    ; Check for brute force (2 or more failures)
    CMP FAILED_ATTEMPTS, 2
    JGE LBF_ALERT
    
    CALL SHOW_REMAINING_ATTEMPTS
    JMP LBF_LOOP

LBF_ALERT:
    MOV BRUTEFORCE_FLAG, 1
    LEA DX, MSG_BRUTEFORCE
    MOV AH, 09H
    INT 21H
    CALL SHOW_REMAINING_ATTEMPTS
    JMP LBF_LOOP

LBF_SUCCESS:
    LEA DX, MSG_CORRECT
    MOV AH, 09H
    INT 21H
    JMP LBF_END

LBF_LOCKED:
    LEA DX, MSG_LOCKED
    MOV AH, 09H
    INT 21H

LBF_END:
    POP AX
    RET
LOGIN_BRUTEFORCE_MODE ENDP

; ============ LOGIN WITH DICTIONARY ATTACK DETECTION ============
LOGIN_DICTIONARY_MODE PROC
    PUSH AX
    
    LEA DX, NEWLINE
    MOV AH, 09H
    INT 21H
    
    LEA DX, MSG_HINT
    MOV AH, 09H
    INT 21H

LD_LOOP:
    CMP FAILED_ATTEMPTS, 3
    JGE LD_LOCKED
    
    INC TOTAL_ATTEMPTS
    
    LEA DX, MSG_PROMPT
    MOV AH, 09H
    INT 21H
    
    CALL GET_PASSWORD
    
    ; Check dictionary
    CALL CHECK_DICTIONARY_ATTACK
    CMP AL, 1
    JE LD_DICT_DETECTED
    
    CALL COMPARE_PASSWORDS
    CMP AL, 1
    JE LD_SUCCESS
    
    INC FAILED_ATTEMPTS
    LEA DX, MSG_INCORRECT
    MOV AH, 09H
    INT 21H
    CALL SHOW_REMAINING_ATTEMPTS
    JMP LD_LOOP

LD_DICT_DETECTED:
    MOV DICTIONARY_FLAG, 1
    LEA DX, MSG_DICTIONARY
    MOV AH, 09H
    INT 21H
    INC FAILED_ATTEMPTS
    CALL SHOW_REMAINING_ATTEMPTS
    JMP LD_LOOP

LD_SUCCESS:
    LEA DX, MSG_CORRECT
    MOV AH, 09H
    INT 21H
    JMP LD_END

LD_LOCKED:
    LEA DX, MSG_LOCKED
    MOV AH, 09H
    INT 21H

LD_END:
    POP AX
    RET
LOGIN_DICTIONARY_MODE ENDP

; ============ GET PASSWORD PROCEDURE ============
GET_PASSWORD PROC
    PUSH AX
    PUSH CX
    PUSH SI
    
    ; Clear input buffer
    LEA SI, INPUT_BUFFER
    MOV CX, 20
GP_CLEAR:
    MOV BYTE PTR [SI], '$'
    INC SI
    LOOP GP_CLEAR
    
    ; Read password
    LEA SI, INPUT_BUFFER
    MOV CX, 0

GP_INPUT:
    MOV AH, 01H
    INT 21H
    
    CMP AL, 0DH
    JE GP_DONE
    
    MOV [SI], AL
    INC SI
    INC CX
    
    CMP CX, 20
    JL GP_INPUT

GP_DONE:
    MOV BYTE PTR [SI], '$'
    
    POP SI
    POP CX
    POP AX
    RET
GET_PASSWORD ENDP

; ============ COMPARE PASSWORDS PROCEDURE ============
COMPARE_PASSWORDS PROC
    PUSH BX
    PUSH CX
    PUSH SI
    PUSH DI
    
    LEA SI, INPUT_BUFFER
    LEA DI, STORED_PASSWORD
    MOV CX, PASSWORD_LENGTH

CP_LOOP:
    MOV AL, [SI]
    MOV BL, [DI]
    
    CMP AL, BL
    JNE CP_NOT_MATCH
    
    INC SI
    INC DI
    LOOP CP_LOOP
    
    MOV AL, 1
    JMP CP_END

CP_NOT_MATCH:
    MOV AL, 0

CP_END:
    POP DI
    POP SI
    POP CX
    POP BX
    RET
COMPARE_PASSWORDS ENDP

; ============ CHECK DICTIONARY ATTACK ============
CHECK_DICTIONARY_ATTACK PROC
    PUSH SI
    PUSH DI
    PUSH CX
    
    ; Check against weak password 1
    LEA SI, INPUT_BUFFER
    LEA DI, WEAK_PASS1
    CALL COMPARE_STRINGS
    CMP AL, 1
    JE CDA_FOUND
    
    ; Check against weak password 2
    LEA SI, INPUT_BUFFER
    LEA DI, WEAK_PASS2
    CALL COMPARE_STRINGS
    CMP AL, 1
    JE CDA_FOUND
    
    ; Check against weak password 3
    LEA SI, INPUT_BUFFER
    LEA DI, WEAK_PASS3
    CALL COMPARE_STRINGS
    CMP AL, 1
    JE CDA_FOUND
    
    ; Check against weak password 4
    LEA SI, INPUT_BUFFER
    LEA DI, WEAK_PASS4
    CALL COMPARE_STRINGS
    CMP AL, 1
    JE CDA_FOUND
    
    ; Check against weak password 5
    LEA SI, INPUT_BUFFER
    LEA DI, WEAK_PASS5
    CALL COMPARE_STRINGS
    CMP AL, 1
    JE CDA_FOUND
    
    MOV AL, 0
    JMP CDA_END

CDA_FOUND:
    MOV AL, 1

CDA_END:
    POP CX
    POP DI
    POP SI
    RET
CHECK_DICTIONARY_ATTACK ENDP

; ============ COMPARE STRINGS HELPER ============
COMPARE_STRINGS PROC
    PUSH CX
    MOV CX, 20

CS_LOOP:
    MOV AL, [SI]
    MOV BL, [DI]
    
    CMP AL, '$'
    JE CS_CHECK_END
    
    CMP BL, '$'
    JE CS_NOT_MATCH
    
    CMP AL, BL
    JNE CS_NOT_MATCH
    
    INC SI
    INC DI
    LOOP CS_LOOP

CS_CHECK_END:
    CMP BL, '$'
    JNE CS_NOT_MATCH
    MOV AL, 1
    JMP CS_END

CS_NOT_MATCH:
    MOV AL, 0

CS_END:
    POP CX
    RET
COMPARE_STRINGS ENDP

; ============ SHOW REMAINING ATTEMPTS ============
SHOW_REMAINING_ATTEMPTS PROC
    PUSH AX
    PUSH DX
    
    LEA DX, MSG_ATTEMPTS
    MOV AH, 09H
    INT 21H
    
    MOV AL, MAX_ATTEMPTS
    SUB AL, FAILED_ATTEMPTS
    ADD AL, 30H
    MOV DL, AL
    MOV AH, 02H
    INT 21H
    
    LEA DX, NEWLINE
    MOV AH, 09H
    INT 21H
    
    POP DX
    POP AX
    RET
SHOW_REMAINING_ATTEMPTS ENDP

; ============ DISPLAY AUDIT REPORT ============
DISPLAY_AUDIT PROC
    PUSH AX
    PUSH DX
    
    LEA DX, MSG_AUDIT
    MOV AH, 09H
    INT 21H
    
    ; Total attempts
    LEA DX, MSG_TOTAL
    MOV AH, 09H
    INT 21H
    
    MOV AL, TOTAL_ATTEMPTS
    ADD AL, 30H
    MOV DL, AL
    MOV AH, 02H
    INT 21H
    
    ; Failed attempts
    LEA DX, MSG_FAILED
    MOV AH, 09H
    INT 21H
    
    MOV AL, FAILED_ATTEMPTS
    ADD AL, 30H
    MOV DL, AL
    MOV AH, 02H
    INT 21H
    
    ; Status
    LEA DX, MSG_STATUS
    MOV AH, 09H
    INT 21H
    
    MOV AL, FAILED_ATTEMPTS
    CMP AL, MAX_ATTEMPTS
    JGE DA_LOCKED_STATUS
    
    CMP TOTAL_ATTEMPTS, 0
    JE DA_NORMAL_STATUS
    
    LEA DX, MSG_SUCCESS_STATUS
    MOV AH, 09H
    INT 21H
    JMP DA_THREATS

DA_LOCKED_STATUS:
    LEA DX, MSG_FAILED_STATUS
    MOV AH, 09H
    INT 21H
    JMP DA_THREATS

DA_NORMAL_STATUS:
    LEA DX, MSG_NORMAL_STATUS
    MOV AH, 09H
    INT 21H

DA_THREATS:
    LEA DX, MSG_THREATS
    MOV AH, 09H
    INT 21H
    
    ; Check flags
    MOV AL, 0
    
    CMP BRUTEFORCE_FLAG, 1
    JNE DA_CHECK_DICT
    LEA DX, MSG_BRUTE_THREAT
    MOV AH, 09H
    INT 21H
    MOV AL, 1

DA_CHECK_DICT:
    CMP DICTIONARY_FLAG, 1
    JNE DA_CHECK_NO_THREAT
    LEA DX, MSG_DICT_THREAT
    MOV AH, 09H
    INT 21H
    MOV AL, 1

DA_CHECK_NO_THREAT:
    CMP AL, 0
    JNE DA_END
    LEA DX, MSG_NO_THREAT
    MOV AH, 09H
    INT 21H

DA_END:
    POP DX
    POP AX
    RET
DISPLAY_AUDIT ENDP

; ============ PAUSE PROCEDURE ============
PAUSE PROC
    PUSH AX
    PUSH DX
    
    LEA DX, MSG_PRESS_KEY
    MOV AH, 09H
    INT 21H
    
    MOV AH, 01H
    INT 21H
    
    POP DX
    POP AX
    RET
PAUSE ENDP

END MAIN