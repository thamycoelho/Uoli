.data 

.text
.align 4

set_motor_speed:
    ldrb r2, [r0]
    ldrb r1, [r0, #1]
    mov r0, r2
    
    mov r7, #18
    svc 0x0

set_motors_speed:
    ldrb r0, [r0, #1]
    ldrb r1, [r1, #1]

    mov r7, #19
    svc 0x0

  
