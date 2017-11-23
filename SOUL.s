.data 
@ Alocando espaco para o contador
CONTADOR:
    .word 0x0

@ Alocando um espaco para a pilha de IRQ
pilha_IRQ:
    .skip 64
sp_irq:
  
pilha_super:
    .skip 100
sp_SUPER:
    
pilha_user:
    .skip 300
sp_user:
.text

.org 0x0
.section .iv, "a"

    @ Definicao do TIME_SZ
    .equ TIME_SZ, 100

    @ flag para desabilitar interrupcao nos modos FIQ e IRQ 
    .equ I_IRQ, 0x40
    .equ I_FIQ, 0x80

    @ flag para os modos IRQ sem interrupcoes
    .equ MODO_IRQ, 0x12+I_IRQ+I_FIQ

    @ flag para o modo supervisor
    .equ MODO_SUPERVISOR, 0x13
    .equ MODO_SUPER_INTERRUPTION, MODO_SUPERVISOR+I_IRQ+I_FIQ

    @ Mascaras para acessar os endereços de GPT
    .equ GPT_CR,     0x53FA0000
    .equ GPT_PR,     0x53FA0004
    .equ GPT_SR,     0x53FA0008
    .equ GPT_IR,     0x53FA000C
    .equ GPT_OCR1,   0X53FA0010
    .equ GPT_OCR2,   0x53FA0014
    .equ GPT_OCR3,   0x53FA0018
    .equ GPT_ICR1,   0x53FA001C
    .equ GPT_ICR2,   0x53FA0020
    .equ GPT_CNT,    0x53FA0024

_start:

interrupt_vector:
    b RESET_HANDLER

.org 0x08
    b SYSCALL_HANDLE

.org 0x18
    b IRQ_HANDLE

.org 0x100 

RESET_HANDLER:
    
    @Zera o cotador
    ldr r2, =CONTADOR
    mov r0, #0
    str r0, [r2]
    
    @Faz o registrador que aponta pra tabela de interrupcoes apontar pra tabela interrupt_vector
    ldr r0, =interrupt_vector
    mcr p15, 0, r0, c12, c0, 0

    msr  CPSR,  MODO_IRQ  @IRQ mode sem interrupcoes 
    ldr r0, =sp_irq
    mov sp, r0
    
    @habilita o clock_src no GPT
    ldr r0, =GPT_CR
    mov r1, #0x41
    str r1, [r0]

    @zerando o prescaler
    mov r0, #0
    ldr r1, =GPT_PR
    str r0, [r1]

    @colocando em GPT_OCR1 o valor que desejo contar (no caso 100)
    mov r0, #100
    ldr r1, =GPT_OCR1
    str r0, [r1]

    @colocando o valor 1 no registrador GPT_IR para habilitar a interrupcao output chanel 1
    mov r0, #1
    ldr r1, =GPT_IR
    str r0, [r1]
    
SET_TZIC:
    @ Constantes para os enderecos do TZIC
    .set TZIC_BASE,             0x0FFFC000
    .set TZIC_INTCTRL,          0x0
    .set TZIC_INTSEC1,          0x84 
    .set TZIC_ENSET1,           0x104
    .set TZIC_PRIOMASK,         0xC
    .set TZIC_PRIORITY9,        0x424

    @ Liga o controlador de interrupcoes
    @ R1 <= TZIC_BASE

    ldr r1, =TZIC_BASE

    @ Configura interrupcao 39 do GPT como nao segura
    mov r0, #(1 << 7)
    str r0, [r1, #TZIC_INTSEC1]

    @ Habilita interrupcao 39 (GPT)
    @ reg1 bit 7 (gpt)

    mov r0, #(1 << 7)
    str r0, [r1, #TZIC_ENSET1]

    @ Configure interrupt39 priority as 1
    @ reg9, byte 3

    ldr r0, [r1, #TZIC_PRIORITY9]
    bic r0, r0, #0xFF000000
    mov r2, #1
    orr r0, r0, r2, lsl #24
    str r0, [r1, #TZIC_PRIORITY9]

    @ Configure PRIOMASK as 0
    eor r0, r0, r0
    str r0, [r1, #TZIC_PRIOMASK]

    @ Habilita o controlador de interrupcoes
    mov r0, #1
    str r0, [r1, #TZIC_INTCTRL]

    @ volta para o modo supervisor     
    msr CPSR_c, #0x13

    ldr sp, =sp_SUPER

    @ configura o GPIO
 
SET_GPIO:
    @ Constantes para os enderecos do GPIO
    .set GPIO_DR,  0x53F84000
    .set GPIO_GDIR, 0x4
    .set GPIO_PSR, 0x8     
     
    @ mascara para configurar os pinos do GPIO, como pinos de entrada ou saida
    .set GPIO_PINO, 0xFFFC003E

    @ Codificando o GDIR
    ldr r0, =GPIO_DR
    ldr r1, =GPIO_PINO
    str r1,[r0, #GPIO_GDIR]
      
    @instrucao msr - habilita interrupcoes
    mov r0, #0x10
    bic r0, r0, #0x80

    msr  cpsr, r0       @ USER mode
 
    @ TRANSFERE  o fluxo para o codigo do usuario
    .set COD_USER, 0x77812000
    
    ldr sp, =sp_user
    ldr r0, =COD_USER
    bx r0
   
IRQ_HANDLE:
    push {r0-r11,lr}
    
    @ Coloca em GPT_SR o valor 0x1
    ldr r0, =GPT_SR
    mov r1, #0x1
    str r1, [r0]

    @ Incrementando o contador em uma unidade
    ldr r0, =CONTADOR
    ldr r1, [r0]
    add r1, #1
    str r1, [r0]

    pop {r0-r11,lr}
    push {r0-r11}
    @ Subtraindo em 4 unidades o LR
    sub lr, #4
    
    pop {r0-r11}
    movs pc, lr 

@ Tratamento das Syscalls
SYSCALL_HANDLE:
    @ Definicao da velocidade maxima
    .set MAX_SPEED, 63
    
    @ Verifica qual a syscall chamada    
    
    cmp r7, #16
    beq read_sonar
    cmp r7, #17
    beq register_proximity_callback
    cmp r7, #18
    beq set_motor_speed
    cmp r7, #19
    beq set_motors_speed
    cmp r7, #20
    beq get_time
    cmp r7, #21
    beq set_time
    cmp r7, #22
    beq set_alarm

@ Define a velocidade do motor 0 ou do motor 1
@ Parametros: 
@ R0: Identificador dos motores
@ r1: Velocidade
@ Retorno:
@ r0: -1 caso o identificador do motor seja invalido, -2 caso a velocidade seja invalida, 0 caso aplicou a velocidade
    
set_motor_speed:
    push {r4-r11}
    @ Mascara para pegar a velocidade do motor e setar o motor_write
    .set SET_MOTOR0,    0x01FC0000
    .set SET_MOTOR1,    0xFE000000
     
    @ caso a velocidade do motor tenha mais que 6 bits (valor maximo 63), entao retorna com r1 = -2
    cmp r0, #1
    movhi r0, #-1
    pop {r4-r11}
    movhis pc, lr
    push {r4-r11}
    
    cmp r1, #63
    movhi r0, #-2
    pop {r4-r11}
    movhis pc, lr
    
    push {r4-r11}
    @ verifica se vai setar o motor 0
    cmp r0, #0

    mov r2, #0
    orr r2, r2, r1, lsl #1
    ldr r0, =GPIO_DR
    ldr r1, [r0]
    biceq r1, r1, #SET_MOTOR0
    bicne r1, r1, #SET_MOTOR1
    orreq r1, r1, r2, lsl #18
    orrne r1, r1, r2, lsl #25
    str r1, [r0]
    
    mov r0, #0
    pop {r4-r11}
    movs pc, lr
        
@ Define a velocidade dos motores
@ Parametros:
@ r0: velocidade para o motor 0
@ r1: velocidade para o motor 1
@ retorno:
@ r0: -1 caso a velocidade do motor 0 seja invalida, -2 caso a velocidade do motor 1 seja invalida, 0 caso definiu as velocidades

set_motors_speed:
    push {r4-r11}
    @ Mascara para aplicar a velocidade dos motores
    .set SET_MOTORS, 0xFFFC0000

    @ Verifica se a velocidade eh maior que a maxima permitida
    cmp r0, #MAX_SPEED
    movhi r0, #-1
    movhis pc, lr
    cmp r1, #MAX_SPEED
    movhi r0, #-2
    
    pop {r4-r11}
    movhis pc, lr
    push {r4-r11}

    @ coloca em r2 os valores em sequencia dos bits de escrita e as velocidades dos motores
    mov r2, #0
    orr r2, r0, r0, lsl #1
    orr r2, r1, r1, lsl #7
    
    @ coloca no GPIO_DR os valores necessarios
    ldr r0, =GPIO_DR
    ldr r1, [r0]
    ldr r3, =SET_MOTORS
    bic r1, r1, r3
    orr r1, r1, r2, lsl #18
    str r1, [r0]

    @ retorna para o codigo do usuario
    mov r0, #0
    pop {r4-r11}
    movs pc, lr
   
@ Funcao retorna o tempo do sistema
@ Retorno:
@ r0: tempo do sistema

get_time:
    push {r4-r11}
    ldr r0, =CONTADOR
    ldr r1, [r0]
    mov r0, r1
    
    pop {r4-r11}
    movs pc, lr

@ Funcao define um tempo para o sistema
@ Parametros:
@ r0: tempo do sistema

set_time:
    push {r4-r11}
    ldr r1, =CONTADOR
    str r0, [r1]

    pop {r4-r11}
    movs pc, lr

@ Funcao le o dado do sonar 
@ Paramentros: 
@ r0: Identificador do sonar
@ Retorno:
@ r0: -1 caso o identificador do sonar seja invalido, valor lido no sonar caso seja um sonar valido

read_sonar:
    push {r4-r11}
    
    @ mascara para modificar o MUX em GPIO_DR
    .equ SONARES, 0x3E
    .equ LER_SONARES, 0x3FFC0

    cmp r0, #15
    movhi r0, #-1
    pop {r4 - r11}
    movhis pc, lr
    
    push {r4-r11}
    @ r2 contem o conteudo de GPIO_DR
    ldr r1, =GPIO_DR
    ldr r2, [r1]
    
    @ zera o trigger e coloca o id do sonar
    bic r2, #SONARES 
    orr r2, r2, r0, lsl #2
    str r2, [r1]

    mov r3, #0
for_time1:
    cmp r3, #50
    bge fim_for_time1
    add r3, #1
    b for_time1
fim_for_time1:

    @ coloca 1 no trigger    
    mov r3, #2
    orr r2, r2, r3
    str r2, [r1]

    mov r3, #0
for_time2:
    cmp r3, #50
    bge fim_for_time2
    add r3, #1
    b for_time2
fim_for_time2:

    @zera o trigger de novo
    ldr r2, [r1]
    bic r2, #2 
    str r2, [r1]
    
loop:
    mov r3, #0
for_time3:
    cmp r3, #50
    bge fim_for_time3
    add r3, #1
    b for_time3
fim_for_time3:

    @ verifica se a flag eh 1
    ldr r2, [r1]
    and r2, r2, #1
    cmp r2, #1
    beq fim_loop
    b loop
fim_loop:
    
    @ Le a distamcia do sonar
    ldr r1, =GPIO_DR
    ldr r0, [r1, #GPIO_PSR] @ Em r0 tem o conteudo do GPIO_PSR
    ldr r2, =LER_SONARES 
    and r0, r0, r2
    mov r0, r0, lsr #6

    pop {r4 - r11}
    movs pc, lr

set_alarm:
    ldrb r1, [r0]

register_proximity_callback:
