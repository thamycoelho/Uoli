#include "api_robot2.h"

#define VELOCIDADE 20

motor_cfg_t motor0;
motor_cfg_t motor1;

void acelera();
void ajusta_parede();
void vira_90();
int gtime, j;

void _start(){
    int i, time;

    /* Inicializa os motores e a ronda com zero */
    motor0.id = 0;
    motor1.id = 1;
    j = 0;
    
    /* Registra os callbacks para nao colidir com a parde */
    register_proximity_callback(3, 800, &ajusta_parede);
    register_proximity_callback(4, 800, &ajusta_parede);

    /* Faz o Uoli andar reto e inicia o loop de alarmes */
    acelera();
    add_alarm(&vira_90, 1);
    while(1);
}

/* Seta os dois motores pra velocidade definida */
void acelera(){
    motor0.speed = VELOCIDADE;
    motor1.speed = VELOCIDADE;
    set_motors_speed(&motor0, &motor1);
}

/* Gira o Uoli para direita ate nao existir mais parede em sua frente */
void ajusta_parede(){
    motor0.speed = 0;
    set_motor_speed(&motor0);

    while(read_sonar(3) < 600);

    motor0.speed = VELOCIDADE;
    set_motor_speed(&motor0);
}

/* Faz o Uoli andar reto de novo e cria um alarme para a proxima curva */
void segue_reto(){
    motor0.speed = VELOCIDADE;
    set_motor_speed(&motor0);

    get_time(&gtime);
    if(j == 50)
        j = 0;
    j++;
    add_alarm(&vira_90, gtime+j);
}

/* Faz o Uoli fazer uma curva e cria um alarme para andar reto novamente*/
void vira_90(){
    motor0.speed = 0;
    set_motor_speed(&motor0);

    get_time(&gtime);
    add_alarm(&segue_reto, gtime+2);
}

