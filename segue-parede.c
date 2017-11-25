#include "api_robot2.h"

motor_cfg_t motor0;
motor_cfg_t motor1;
unsigned char sonar_id;
unsigned short sonar_valor;
unsigned short sonar_valor1;
unsigned short sonar_valor2;
unsigned int time;
unsigned int nextTime;
int i;

void *vira_uoli();

int _start(int argv, char** argc){

    sonar_id = 4;
    register_proximity_callback(sonar_id, 1200, vira_uoli);
    motor0.id = 0;
    motor0.speed = 40;
    motor1.id = 1;
    motor1.speed = 40;
    set_motors_speed(&motor0, &motor1);
    
    while(1);
    return 0;
}

void *vira_uoli(){
    motor0.speed = 0;
    set_motor_speed(&motor0);

    get_time(&time);
    nextTime = time + 3;
    while(time != nextTime)
         get_time(&time);

    motor0.speed = 40;
    set_motor_speed(&motor0);
}

