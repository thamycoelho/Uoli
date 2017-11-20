.global set_motor_speed
.global set_motors_speed
.global read_sonar

.data 


.text
.align 4

set_motor_speed:
    ldrb r2, [r0]
    ldrb r1, [r0, #1]
    mov r0, r2
    
    mov r7, #18
    svc 0x0
    mov pc, lr

set_motors_speed:
    ldrb r2, [r0, #1]
    ldrb r3, [r1, #1]

    mov r0, r2
    mov r1, r3

    mov r7, #19
    svc 0x0
    mov pc, lr

read_sonar:
    ldrb r1, [r0]
    mov r0, r1
    
    mov r7, #16
    svc 0x0
    mov pc,lr
