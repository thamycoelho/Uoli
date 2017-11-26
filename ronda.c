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

    motor0.id = 0;
    motor1.id = 1;
    j = 0;

    register_proximity_callback(3, 800, &ajusta_parede);
    register_proximity_callback(4, 800, &ajusta_parede);

    acelera();
    add_alarm(&vira_90, 1);
    while(1);
}

void acelera(){
    motor0.speed = VELOCIDADE;
    motor1.speed = VELOCIDADE;
    set_motors_speed(&motor0, &motor1);
}

void ajusta_parede(){
    motor0.speed = 0;
    set_motor_speed(&motor0);

    while(read_sonar(3) < 600);

    motor0.speed = VELOCIDADE;
    set_motor_speed(&motor0);
}

void para_motor(){
    motor0.speed = VELOCIDADE;
    set_motor_speed(&motor0);

    get_time(&gtime);
    if(j == 50)
        j = 0;
    j++;
    add_alarm(&vira_90, gtime+j);
}

void vira_90(){
    motor0.speed = 0;
    set_motor_speed(&motor0);

    get_time(&gtime);
    add_alarm(&para_motor, gtime+2);
}

