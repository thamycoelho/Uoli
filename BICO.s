.data 

.text
.align 4

_start:

set_motor_speed:
    ldrb r2, [r0]
    ldrb r1, [r0, #1]
    mov r0, r2
    
    mov r7, #18
    svc 0x0

    
