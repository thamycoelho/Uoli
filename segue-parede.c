#include "api_robot2.h"

motor_cfg_t motor0;
motor_cfg_t motor1;
unsigned char sonar_id;
unsigned short sonar_valor;
unsigned short sonar_valor1;
unsigned short sonar_valor2;

int _start(int argv, char** argc){
    int i;

    sonar_id = 4;
    motor0.id = 0;
    motor0.speed = 40;
    motor1.id = 1;
    motor1.speed = 40;
    set_motors_speed(&motor0, &motor1);

    while(1){
        sonar_valor1 = read_sonar(sonar_id);
        sonar_valor2 = read_sonar(sonar_id);
        sonar_valor = sonar_valor1 > sonar_valor2 ? sonar_valor1 : sonar_valor2;

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
