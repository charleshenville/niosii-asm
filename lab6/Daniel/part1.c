int main(){
	volatile int* LEDs = 0xff200000; //set correct memory values to LEDs and
	volatile int* KEY_Edge_Cap = 0xff20005C; //edge capture for the KEYs
	
	*LEDs = 0; //intialize value of LED
	*KEY_Edge_Cap = 0xF; //Reset Edge Cap Reg
	
	while(1){
		if((*KEY_Edge_Cap & 1) == 1){ //check is KEY0 was pressed
			*LEDs = 0x3FF; //turn on all LEDs
			*KEY_Edge_Cap = 1; //reset bit 0 of edge capture
		} else if((*KEY_Edge_Cap & 2) == 2){ //check is KEY1 was pressed
			*LEDs = 0; //turn off all LEDs
			*KEY_Edge_Cap = 2; //reset bit 1 of edge capture
		}
	}
	
	return 0;
}