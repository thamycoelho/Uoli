#include "api_robot2.h"

int _start(int argv, char** argc){
    motor_cfg_t motor0;
    motor_cfg_t motor1;

    motor0.id = 0;
    motor0.speed = 40;
    motor1.id = 1;
    motor1.speed = 40;

        set_motors_speed(&motor0, &motor1);
    
    return 0;
}
