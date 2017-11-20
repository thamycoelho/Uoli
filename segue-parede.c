#include "api_robot2.h"

motor_cfg_t motor0;
motor_cfg_t motor1;
unsigned char sonar_id;

int _start(int argv, char** argc){

    motor0.id = 0;

    motor0.speed = 40;


    motor1.id = 1;

    motor1.speed = 40;
    sonar_id = 4;

    set_motors_speed(&motor0, &motor1);

    if(read_sonar(sonar_id) < 1200){
        motor0.speed = 0;
        motor1.speed = 1;   
        set_motors_speed(&motor0, &motor1);
    }

    while(1);
    return 0;
}
