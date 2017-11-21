#include "api_robot2.h"

motor_cfg_t motor0;
motor_cfg_t motor1;
unsigned char sonar_id;
unsigned short sonar_valor;
int _start(int argv, char** argc){

    motor0.id = 0;

    motor0.speed = 40;


    motor1.id = 1;

    motor1.speed = 40;
    sonar_id = 4;

    sonar_valor = read_sonar(sonar_id);
    

    while(1);
    return 0;
}
