#include "api_robot2.h"

motor_cfg_t motor0;
motor_cfg_t motor1;
unsigned char sonar_id;
unsigned short sonar_valor;

int _start(int argv, char** argc){
int i;
    sonar_id = 4;
    while(1){
        sonar_valor = read_sonar(sonar_id);
        if(sonar_valor < 20){
            motor1.speed = 0;
            motor0.speed = 0;
            set_motors_speed(&motor0,&motor1);
            break;
        }
        
        motor0.id = 0;
      	motor0.speed = 40;
    	motor1.id = 1;
    	motor1.speed = 40;
	
    	set_motors_speed(&motor0, &motor1);
	
//    	if(read_sonar(sonar_id) <= 50){
  //          motor1.speed = 0;
    //        set_motor_speed(&motor1);
      //  }
            
    }

    while(1);
    return 0;
}
