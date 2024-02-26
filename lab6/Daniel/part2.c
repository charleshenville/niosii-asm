struct audio_t {
	volatile unsigned int control; // The control/status register
	volatile unsigned char RARC; // the 8 bit RARC register
	volatile unsigned char RALC; // the 8 bit RALC register
	volatile unsigned char WSRC; // the 8 bit WSRC register
	volatile unsigned char WSLC; // the 8 bit WSLC register
	volatile unsigned int ldata; // the 32 bit (really 24) left data register
	volatile unsigned int rdata; // the 32 bit (really 24) right data register
};

int main(){
	struct audio_t *const audiop = ((struct audio_t *) 0xff203040); //initalize memory mapped loaction of audio port
	
	while(1){
		if(audiop->RARC){ //checks if there is data to take from input FIFO
			int leftSound = audiop->ldata; //loads left and right data from input FIFO
			int rightSound = audiop->rdata;
			
			audiop->ldata = leftSound; //stores left and right date into output FIFO
			audiop->rdata = rightSound;
		}
	}
	
	return 0;
}