@ Alocando um espaco para a pilha de IRQ
pilha_IRQ:
    .skip 64
sp_irq:

.text

.org 0x0
.section .iv, "a"

@ Definicao do TIME_SZ
.set TIME_SZ, #100

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
    ldr r0, sp_irq
    mov sp, r0
    
    @ volta para o modo supervisor     
    msr CPSR_c, MODO_SUPER_INTERRUPTION

    @habilita o clock_src no GPT
    ldr r0, =GPT_CR
    mov r1, #0x41
    str r1, [r0]

    @zerando o prescaler
    mov r0, #0
    ldr r1, =GPT_PR
    str r0, [r1]

    @colocando em GPT_OCR1 o valor que desejo contar (no caso 100)
    mov r0, TIME_SZ
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
    msr  CPSR_c, #0x10       @ USER mode
 
    @ TRANSFERE  o fluxo para o codigo do usuario
    .set COD_USER, 0x77812000
    
    b COD_USER
   
IRQ_HANDLE:
    @ Coloca em GPT_SR o valor 0x1
    LDR r0, =GPT_SR
    mov r1, #0x1
    str r1, [r0]

    @ Incrementando o contador em uma unidade
    ldr r0, =CONTADOR
    ldr r1, [r0]
    add r1, #1
    str r1, [r0]

    @ Subtraindo em 4 unidades o PC
    ldr r0, [lr]
    sub r0, #4
    str r0, [lr]

    movs pc, lr 

@ Tratamento das Syscalls
SYSCALL_HANDLE:

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
    @ Mascara para pegar a velocidade do motor e setar o motor_write
    
    @ caso a velocidade do motor tenha mais que 6 bits (valor maximo 63), entao retorna com r1 = -2
    cmp r1, #63
    movhi r1, #-2
    movhis pc, lr

    @ verifica se vai setar o motor 0
    cmp r0, #0
    bne motor_2    

    mov r1, r1, lsl #19
    ldr r0, =GPIO_DR
    str r1, [r0]
    ldr r1, [r0]
    mov r2, #1
    mov r2, r2, lsl #18
    orr r1, r2
    ldr r1, [r0]
    
    mov r0, #0
    msr CPSR_c, 0x10
    movs pc, lr
        
motor_2:
    cmp r0, #1
    bne erro

    mov r1, r1, lsl #26
    ldr r0, =GPIO_DR
    str r1, [r0]
    ldr r1, [r0]
    mov r2, #1
    mov r2, r2, lsl #25
    orr r1, r2
    ldr r1, [r0]
    
    mov r0, #0
    msr CPSR_c, 0x10
    movs pc, lr
    
erro:
    mov r0, #-1
    
    msr CPSR_c, 0x10
    movs pc, lr


