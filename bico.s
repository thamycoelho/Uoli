.global set_motor_speed
.global set_motors_speed
.global read_sonar
.global read_sonars
.global register_proximity_callback
.global add_alarm
.global get_time
.global set_time


.data 


.text
.align 4

@ Chama a syscall set_motor_speed
set_motor_speed:
    push {r4-r11, lr}
    ldrb r2, [r0]
    ldrb r1, [r0, #1]
    mov r0, r2
    
    mov r7, #18
    svc 0x0
    pop {r4-r11, lr}
    mov pc, lr

@ Chama a syscall set_motors_speed
set_motors_speed:
    push {r4-r11, lr}
    ldrb r2, [r0, #1]
    ldrb r3, [r1, #1]

    mov r0, r2
    mov r1, r3

    mov r7, #19
    svc 0x0
    pop {r4-r11, lr}
    mov pc, lr

@ Chama a syscall read sonar
read_sonar:
    push {r4-r11, lr}
    mov r7, #16
    svc 0x0
    pop {r4-r11, lr}
    mov pc,lr

@ Chama a syscal read_sonars
read_sonars:
    push {r4-r11, lr}
    ldr r3, [r2]
    mov r2, r3      @r2 guarda o endereco de memoria do vetor de distancias
    mov r3, r0      @r3 guarda o sonar inicial

loop_sonars:
    cmp r3, r1
    bhi fim_loop_sonars
    
    mov r0, r3      @ Pega o sonar a ser lido e coloca em r0
    
    mov r7, #16   
    svc 0x0         @ Chama a syscall
        
    str r0, [r2]    @ coloca o valor retornado pela syscall no vetor
    add r2, #4      @ vai pra proxima posicao do vetor
    add r3, #1      @ vai pro proximo sonar a ser lido
    b loop_sonars
    
fim_loop_sonars:
    pop {r4-r11, lr}
    mov pc, lr

@ Chama a syscall register_proximity_callback
register_proximity_callback:
    push {r4-r11, lr}


    
    pop {r4-r11, lr}
    mov pc,lr

@ Chama a syscall set_alarm
add_alarm:
    push {r4-r11, lr}

    
    pop {r4-r11, lr}

@ Chama a syscall get_time
get_time:
    push {r4-r11, lr}
    mov r8, r0
    
    mov r7, #20
    svc 0x0

    str r0, [r8]
    pop {r4-r11, lr}
    mov pc, lr

@ Chama a syscall set_time
set_time:
    push {r4-r11, lr}
    mov r7, #21
    svc 0x0

    pop {r4-r11, lr}
    mov pc, lr
