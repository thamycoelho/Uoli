#include "api_robot2.h"

motor_cfg_t motor0;
motor_cfg_t motor1;
unsigned short sonar[2];
unsigned int time;

void *acelera();
void *ajusta_parede();
void *para();
int abs(int a);

int _start(int argv, char** argc){
    add_alarm(para, 10);
    add_alarm(acelera, 20);

    register_proximity_callback(4, 1500, ajusta_parede);

    get_time(&time);
    while(time < 30){
        get_time(&time);
    }

    set_time(0);
    add_alarm(para, 10);
    /*
    while(1){
        sonar[0] = read_sonar(0);
        sonar[1] = read_sonar(15);

        if(abs(sonar[0] - sonar[1]) > 50){
            if(sonar[0] > sonar[1]){
                motor1.speed = 35;
                set_motor_speed(&motor1);
            }
            else{
                motor0.speed = 35;
                set_motor_speed(&motor0);
            }
        }
        else{
            motor0.speed = motor1.speed = 40;
            set_motor_speed(&motor0);
            set_motor_speed(&motor1);
        }
    }
    */
    while(1);
    return 0;
}

void *acelera(){
    motor0.id = 0;
    motor0.speed = 40;
    motor1.id = 1;
    motor1.speed = 40;

    set_motors_speed(&motor0, &motor1);
}

void *ajusta_parede(){
    motor0.speed = 0;
    set_motor_speed(&motor0);

    while(read_sonar(0) > 1200);

    motor0.speed = 40;
    set_motor_speed(&motor0);
}

void *para(){
    motor0.speed = 0;
    motor1.speed = 0;

    set_motors_speed(&motor0, &motor1);
}
int abs(int a){
    return a < 0 ? -a : a;
}
