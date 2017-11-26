#include "api_robot2.h"

#define VELOCIDADE 30

motor_cfg_t motor0;
motor_cfg_t motor1;

void ajusta_parede();
void acelera();
void cola_parede();

void _start(){
    motor0.id = 0;
    motor1.id = 1;

    register_proximity_callback(4, 600, &ajusta_parede);
    register_proximity_callback(3, 600, &ajusta_parede);
    
    acelera();

    while(1);
}

void cola_parede(){
    while(read_sonar(0) < 650){
        if(read_sonar(0) < 300 || read_sonar(3) < 650 || read_sonar(4) < 650)
            return;
    }

    motor1.speed = 2*VELOCIDADE/3;
    set_motor_speed(&motor1);

    while(read_sonar(0) > 600 && read_sonar(2) > 800);

    motor1.speed = VELOCIDADE;
    set_motor_speed(&motor1);
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

    cola_parede();
}
