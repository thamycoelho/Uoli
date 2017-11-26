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

.text

RESET_HANDLER:

    @Zera o cotador
    ldr r2, =contador
    mov r0, #0
    str r0, [r2]
    
    @Faz o registrador que aponta pra tabela de interrupcoes apontar pra tabela interrupt_vector
    ldr r0, =interrupt_vector
    mcr p15, 0, r0, c12, c0, 0

    @habilita o clock_src no GPT
    ldr r0, =GPT_CR
    mov r1, #0x41
    str r1, [r0]

    @zerando o prescaler
    mov r0, #0
    ldr r1, =GPT_PR
    str r0, [r1]

    @colocando em GPT_OCR1 o valor que desejo contar (no caso 100)
    mov r0, #TIME_SZ
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

    msr  CPSR,  MODO_IRQ  @IRQ mode sem interrupcoes 
    
    @ inicializa pilha do modo IRQ
    ldr r0, =sp_irq
    mov sp, r0

    @ Troca para o modo system e inicializa a pilha desse modo
    msr CPSR_c, #0x1F
    ldr sp, =sp_system
   
    @ volta para o modo supervisor e inicializa a pilha do modo    
    msr CPSR_c, #0x13
    ldr sp, =sp_super

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
      
    @ Troca de modo, para o modo usuario e  habilita interrupcoes
    msr  cpsr, #0x10       
 
    @ TRANSFERE  o fluxo para o codigo do usuario
    .set COD_USER, 0x77812000
    ldr r0, =COD_USER
    bx r0

@ Tratando interrupcoes do tipo IRQ   
IRQ_HANDLE:
    push {r0-r12,lr}
    
    @ Salvando o SPSR na pilha
    mrs r0, SPSR
    push {r0}
    
    @ Coloca em GPT_SR o valor 0x1
    ldr r0, =GPT_SR
    mov r1, #0x1
    str r1, [r0]

@ Rotinha do alarm
alarm:
    @ Verifica se tem uma callback ou alarme sendo executada, se tiver vai pro final
    ldr r0, =callflag
    ldr r1, [r0]
    cmp r1, #1

    beq fim_percorre_vetor_callback

    @ em r1 tem a quantidade de alarms adicionados e em r2 o i do loop
    ldr r0, =qtd_alarm
    ldr r6, [r0]
    mov r2, #0

@ Percorre os vetores de alarm comparando o tempo do sistema e executando a fução caso esteja no tempo
percorre_vetor_alarm:
    cmp r2, r6
    bhs fim_perccore_vetor_alarm
    mov r3, r2, lsl #2
    ldr r4, =alarm_time_vector
    ldr r5, [r4, r3]
    
    @ Chama syscall get_time    
    mov r7, #20
    svc 0x0

    cmp r0, r5
    blo proximo_alarm
    ldr r4, =alarm_function_vector
    ldr r5, [r4, r3]

    ldr r4, =callflag
    mov r7, #1
    str r7, [r4]

    push {r0-r11, lr}
    blx r5
    pop {r0- r11, lr}
    
    ldr r4, =callflag
    mov r7, #0
    str r7, [r4]

    mov r3, r2
    sub r6, #1
deleta_alarm:
    cmp r3, r6
    bhi fim_deleta_alarm
    
    mov r4, r3, lsl #2
    add r5, r4, #4
    ldr r0, =alarm_time_vector
    ldr r1, [r0, r5]
    str r1, [r0, r4]

    ldr r0, =alarm_function_vector
    ldr r1, [r0, r5]
    str r1, [r0, r4]
    
    add r3, #1
    b deleta_alarm
fim_deleta_alarm:
    sub r2, #1

proximo_alarm: 
    add r2, #1
    b percorre_vetor_alarm
fim_perccore_vetor_alarm:
    ldr r0, =qtd_alarm
    str r6, [r0]

@ Trata as callbacks programadas
callback:
    @ Verifica a flag de callbaks para verificar se esta ocorrendo uma chamada de callback no momento
    ldr r0, =callflag
    ldr r1, [r0]
    cmp r1, #1
    
    @ Caso esteja ocorrendo uma callback entao termina de tratar a callback que esta ocorrendo, caso contrario percorre o vetor de callbacks 
    beq fim_percorre_vetor_callback
   
    @ Verifica a quantidade de callbacks existentes, se houver mais de uma percorre o vetor
    ldr r0, =qtd_callback
    ldr r1, [r0]
    mov r2, #0

percorre_vetor_callback:
    cmp r2, r1
    bhs fim_percorre_vetor_callback

    @ Corrige a varialvel do loop para a variacao de endereco correta
    mov r3, r2, lsl #2

    @ r0 recebe o id do sonar que deve ser lida a distancia
    ldr r4, =callback_sonar_vector
    ldr r0, [r4, r3]
    
    @ Chama syscall para leiitura do sonar
    mov r7, #16
    svc 0x0
    
    @ r5 recebe a distancia necessaria para chamada da funcao
    ldr r4, =callback_distance_vector
    ldr r5, [r4, r3]
    
    @ Se a distancia for menor ou igual, chama a funcao da callback
    cmp r0, r5
    ldrls r4, =callback_function_vector
    ldrls r5, [r4, r3]

    @ Se for realizar a chamada de funcao, indica na flag que esta ocorendo uma callback
    ldrls r4, =callflag
    movls r6, #1
    strls r6, [r4]

    push {r1-r11,lr}    @ Empilha os registradores 
    blxls r5            @ Chama a funcao requerida pela callback
    pop {r1-r11,lr}     @ Desempilha os registradores

    @ Zera novamente a flag de callbacks 
    ldr r4, =callflag
    mov r5, #0
    str r5, [r4]
    
    @ Continua percorrendo o vetor
    add r2, #1
    b percorre_vetor_callback
fim_percorre_vetor_callback: 
    
    @ Incrementando o contador em uma unidade
    ldr r0, =contador
    ldr r1, [r0]
    add r1, #1
    str r1, [r0]
    
    @ Restaurando SPSR e os demais registradores
    pop {r0}
    msr SPSR, r0
    pop {r0-r12,lr}

    @ Subtrai em 4 unidades o LR e retorna da funcao
    sub lr, #4
    movs pc, lr 
    
@ Tratamento das Syscalls
SYSCALL_HANDLE:
    @ Troca pro modo supervisor sem perder o SPSR do modo do usuario
    mrs r11, SPSR
    push {r11}

    msr CPSR, 0x13

    pop {r11}
    msr SPSR, r11
    
    @ Empilha SPSR e os demais registradores
    push {r1-r12, lr}
    mrs r12, SPSR
    push {r12}
    
    @ Definicao da velocidade maxima
    .equ MAX_SPEED, 63
    .equ MAX_CALLBACK, 8
    .equ MAX_ALARM, 8
    
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

    @ Caso a chamada tenha sido feita para uma syscall invalida, retorna
    pop {r12}
    msr SPSR, r12
    pop {r1-r12, lr}
    movs pc, lr

@ Define a velocidade do motor 0 ou do motor 1
@ Parametros: 
@ R0: Identificador dos motores
@ r1: Velocidade
@ Retorno:
@ r0: -1 caso o identificador do motor seja invalido, -2 caso a velocidade seja invalida, 0 caso aplicou a velocidade
set_motor_speed:
    @ Mascara para pegar a velocidade do motor e setar o motor_write
    .set SET_MOTOR0,    0x01FC0000
    .set SET_MOTOR1,    0xFE000000
    
    @ Caso o id do motor seja invalido, retorna -1
    cmp r0, #1
    movhi r0, #-1
    bhi fim_set_motor_speed
    
    @ Caso a velocidade do motor tenha mais que 6 bits (valor maximo 63), entao retorna -2
    cmp r1, #63
    movhi r0, #-2
    bhi fim_set_motor_speed

    @ verifica se vai setar o motor 0 ou o motor 1
    cmp r0, #0

    @ Coloca a velocidade do motor desejado no registrador GPIO_DR
    mov r2, #0
    orr r2, r2, r1, lsl #1
    ldr r0, =GPIO_DR
    ldr r1, [r0]
    biceq r1, r1, #SET_MOTOR0
    bicne r1, r1, #SET_MOTOR1
    orreq r1, r1, r2, lsl #18
    orrne r1, r1, r2, lsl #25
    str r1, [r0]
    
    @ Caso tenha setado as velocidades, retorna 0
    mov r0, #0
    
fim_set_motor_speed:    
    pop {r12}
    msr SPSR, r12
    pop {r1-r12, lr}
    movs pc, lr
        
@ Define a velocidade dos motores
@ Parametros:
@ r0: velocidade para o motor 0
@ r1: velocidade para o motor 1
@ retorno:
@ r0: -1 caso a velocidade do motor 0 seja invalida, -2 caso a velocidade do motor 1 seja invalida, 0 caso definiu as velocidades
set_motors_speed:
    @ Mascara para aplicar a velocidade dos motores
    .set SET_MOTORS, 0xFFFC0000

    @ Verifica se a velocidade eh maior que a maxima permitida
    cmp r0, #MAX_SPEED
    movhi r0, #-1
    bhi fim_set_motors_speed
    cmp r1, #MAX_SPEED
    movhi r0, #-2
    bhi fim_set_motors_speed
    
    @ coloca em r2 os valores em sequencia dos bits de escrita e as velocidades dos motores
    mov r2, #0
    orr r2, r2, r0, lsl #1
    orr r2, r2, r1, lsl #8
    
    @ coloca no GPIO_DR os valores necessarios
    ldr r0, =GPIO_DR
    ldr r1, [r0]
    ldr r3, =SET_MOTORS
    bic r1, r1, r3
    orr r1, r1, r2, lsl #18
    str r1, [r0]

    @ retorna para o codigo do usuario
    mov r0, #0
fim_set_motors_speed:
    pop {r12}
    msr SPSR, r12
    pop {r1-r12, lr}
    movs pc, lr
   
@ Funcao retorna o tempo do sistema
@ Retorno:
@ r0: tempo do sistema
get_time:
    @ Coloca em r0 o tempo do sistema
    ldr r1, =contador
    ldr r0, [r1]
    
    @ Retorna da syscall
    pop {r12}
    msr SPSR, r12
    pop {r1-r12, lr}
    movs pc, lr

@ Funcao define um tempo para o sistema
@ Parametros:
@ r0: tempo do sistema
set_time:
    @ Inicializa o contador com um valor
    ldr r1, =contador
    str r0, [r1]

    @ Retorna da Syscall
    pop {r12}
    msr SPSR, r12
    pop {r1-r12, lr}
    movs pc, lr

@ Funcao le o dado do sonar 
@ Paramentros: 
@ r0: Identificador do sonar
@ Retorno:
@ r0: -1 caso o identificador do sonar seja invalido, valor lido no sonar caso seja um sonar valido
read_sonar:
    
    @ mascara para modificar o MUX em GPIO_DR
    .equ SONARES, 0x3E
    .equ LER_SONARES, 0x3FFC0

    @ Verifica se o sonar eh valido
    cmp r0, #15
    movhi r0, #-1
    bhi fim_read_sonar 

    @ r2 contem o conteudo de GPIO_DR
    ldr r1, =GPIO_DR
    ldr r2, [r1]
    
    @ zera o trigger e coloca o id do sonar
    bic r2, #SONARES 
    orr r2, r2, r0, lsl #2
    str r2, [r1]

@ Loop para passagem de tempo
    mov r3, #0
for_time1:
    cmp r3, #50
    bhs fim_for_time1
    add r3, #1
    b for_time1
fim_for_time1:

    @ coloca 1 no trigger    
    mov r3, #2
    orr r2, r2, r3
    str r2, [r1]

@ Loop para passagem de tempo
    mov r3, #0
for_time2:
    cmp r3, #50
    bhs fim_for_time2
    add r3, #1
    b for_time2
fim_for_time2:

    @zera o trigger de novo
    ldr r2, [r1]
    bic r2, #2 
    str r2, [r1]
    
@ Aguarda a flag setar o bit
loop:

@ Loop para passagem de tempo
    mov r3, #0
for_time3:
    cmp r3, #50
    bhs fim_for_time3
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

@ Retorna da syscall
fim_read_sonar:
    pop {r12}
    msr SPSR, r12
    pop {r1-r12, lr}
    movs pc, lr

@ Adiciona um alarme
@ Parametros:
@ r0: Ponteiro para funcao a ser chamada na ocorrencia de alarme
@ r1: tempo do sistema
@ Retorno:
@ r0: -1 caso o numero de alarmes seja maior que o permitido, -2 caso o tempo do alarme seja anterior ao tempo do sistema, 0 caso o alarme foi adicionado
set_alarm:
    @ retorna -1 caso a quantidade de alarmes ja tenham esgotado
    ldr r2, =qtd_alarm
    ldr r3, [r2]
    cmp r3, #MAX_ALARM
    movhs r0, #-1
    bhs fim_alarm
    
    @ Verifica o tempo do sistema e compara com o tempo do alarme
    ldr r2, =contador
    ldr r3, [r2]
    cmp r1, r3
    movlo r0, #-2
    blo fim_alarm
    
    @ Arruma o deslocamento dos vetores de alarme
    ldr r2, =qtd_alarm
    ldr r3, [r2]
    mov r3, r3, lsl #2

    @ Coloca o tempo da ocorrencia do alarme no vetor
    ldr r2, =alarm_time_vector
    str r1, [r2, r3]

    @ Coloca a funcao a ser chamada no alarme no vetor
    ldr r2, =alarm_function_vector
    str r0, [r2, r3]
    
    @ Adiciona 1 na quantidade de alarmes
    ldr r2, =qtd_alarm
    ldr r3,[r2]
    add r3, #1
    str r3, [r2]

@ Retorna da syscall
fim_alarm:
    pop {r12}
    msr SPSR, r12
    pop {r1-r12, lr}
    movs pc, lr
    
@ Adiciona uma callback
@ Parametros:
@ r0: id do sonar a ser lido
@ r1: Distancia para a ocorrencia do callback
@ r3: Ponteiro para a funcao chamada pela callback
@ Retornos:
@ r0: -1 caso o numero de callbacks ja estaja no limite, -2 caso o id do sonar seja invalido, 0 caso tenha adicionado o alarme
register_proximity_callback:
    @ Verifica se o sonar eh valido
    cmp r0, #15
    movhi r0, #-2
    bhi callback_fim
    
    @ Verifica a quantidade de callbacks
    ldr r3, =qtd_callback
    ldr r4, [r3]
    cmp r4, #MAX_CALLBACK
    movhs r0, #-1
    bhs callback_fim
    
    @ Pega o deslocamento que deve ser feito ao armazenar dados no vetor
    ldr r3, =qtd_callback
    ldr r4, [r3]
    mov r4, r4, lsl #2

    @ Coloca o id do sonar no vetor
    ldr r3, =callback_sonar_vector
    str r0, [r3, r4]

    @ Coloca a distancia desejada  no vetor
    ldr r3, =callback_distance_vector
    str r1, [r3, r4]

    @ Coloca o ponteiro para a funcao no vetor
    ldr r3, =callback_function_vector
    str r2, [r3, r4]

    @ Adiciona 1 na quantidade de callbacks
    ldr r3, =qtd_callback
    ldr r4, [r3]
    add r4, #1
    str r4, [r3]
    
@ Retorna da syscall
callback_fim:
    pop {r12}
    msr SPSR, r12
    pop {r1-r12, lr}
    movs pc, lr

.data 

@ Flag para controlar chamadas de callback
callflag:
    .word 0x0
@ Alocando espaco para o contador
contador:
    .word 0x0

@ Alocando um espaco para as pilhas do sistema
pilha_irq:
    .skip 1024
sp_irq:

pilha_super:
    .skip 1024
sp_super:
    
pilha_system:
    .skip 1024
sp_system:

@ Alocando espaco para o vetor de callbacks
callback_sonar_vector:
    .space 32
callback_distance_vector:
    .space 32
callback_function_vector:
    .space 32

@ Variavel que contem a quantidade de callbacks
qtd_callback:
    .word 0x0

@ Variavel que contem a quantidade de alarmes
qtd_alarm:
    .word 0x0

@ Alocando espaco para os vetores de alarmes
alarm_function_vector:
    .space 32
alarm_time_vector:
    .space 32
