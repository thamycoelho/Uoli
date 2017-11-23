#include "api_robot2.h"

motor_cfg_t motor0;
motor_cfg_t motor1;
unsigned char sonar_id;
unsigned short sonar_valor;

int _start(int argv, char** argc){
    int i;

    sonar_id = 4;
    motor0.id = 0;
    motor0.speed = 40;
    motor1.id = 1;
    motor1.speed = 40;
    set_motors_speed(&motor0, &motor1);

    while(1){
        sonar_valor = read_sonar(sonar_id);
        if(sonar_valor <= 800){
            motor1.speed = 0;
            motor0.speed = 0;
            set_motors_speed(&motor0,&motor1);
            break;
        }
    }

    while(1);
    return 0;
}
