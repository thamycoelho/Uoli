#include "api_robot2.h"

motor_cfg_t motor0;
motor_cfg_t motor1;
unsigned short sonar[2];
unsigned int time;

int abs(int a);

int _start(int argv, char** argc){
    while(1);
    return 0;
}

int abs(int a){
    return a < 0 ? -a : a;
}


