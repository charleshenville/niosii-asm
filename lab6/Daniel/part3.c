struct audio_t {
	volatile unsigned int control; // The control/status register
	volatile unsigned char RARC; // the 8 bit RARC register
	volatile unsigned char RALC; // the 8 bit RALC register
	volatile unsigned char WSRC; // the 8 bit WSRC register
	volatile unsigned char WSLC; // the 8 bit WSLC register
	volatile unsigned int ldata; // the 32 bit (really 24) left data register
	volatile unsigned int rdata; // the 32 bit (really 24) right data register
};

int FindN(int freq); //finds number of samples in half a period of a given frequency
int FindFreq(int SW_value); //returns a frquency between 100-2000 Hz depending on which switches are up

int main(){
	struct audio_t *const audiop = ((struct audio_t *) 0xff203040); //initalize memory mapped loaction of audio port
	volatile int* SW = 0xff200040; //intialize SW address
	
	int frequency=100; //set minimum frequency
	int N = FindN(frequency); //find the number of sample needed for half a period at set freq
	while(1){
		if(frequency != FindFreq(*SW)){ //used to detect whether there was a change in switches
			frequency = FindFreq(*SW); //find new freq and sample of half a period
			N = FindN(frequency);
		}
		if(audiop->WSRC > (2*N + 1)){ //check is there is enough space in output FIFOs
			for(int i = 0; i < N; i++){ //load half a period with "high"
				audiop->rdata = 0xFFFFFF;
				audiop->ldata = 0xFFFFFF;
			}
			for(int i = 0; i < N; i++){ //load half a period with "low"
				audiop->rdata = 0;
				audiop->ldata = 0;
			}
		}
	}
	return 0;
}

int FindN(int freq){
	freq*=2;
	return 8000/freq;
}
	
int FindFreq(int SW_value){
	int freq = 2*SW_value + 100;
	
	if(freq > 2000) freq = 2000;
	
	return freq;
}
	