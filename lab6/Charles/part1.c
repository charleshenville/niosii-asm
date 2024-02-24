int main(void){
	
	volatile int *KEYs = 0xff200050;
	volatile int *LEDs = 0xff200000;
	int edge_cap;
	
	while(1){
		
		// getting the KEYs edge capture register into the variable edge_cap:
		edge_cap = *(KEYs + 3);
		int clicked = edge_cap & 1;
		
		if(clicked){ // Deal with KEY0 press
			
			*(LEDs) = 1023;
			*(KEYs+3) = 1;
			
		} else {  // Deal with KEY1 press (Maybe)
			
			clicked = edge_cap & 2;
			if (!clicked){continue;}  // Keep polling if KEY1 inactive
			
			*(LEDs) = 0;
			*(KEYs+3) = 2;
			
		}
	
	}
	
	return 0;
	
}
