int main(void) {
	
    volatile int * audio_base = 0xFF203040;
	volatile int * switch_base = 0xFF200040;
	
	const int sample_rate = 8000;
	const int min_frequency = 100;
	const int max_frequency = 2000;
	const int frequency_interval = (max_frequency-min_frequency)/1023;
	
    while (1) {

		int frequency = min_frequency + (*switch_base) * frequency_interval;
		if (frequency > max_frequency) {frequency = max_frequency;}

		const int num_samples_for_half_period = sample_rate/2/frequency;

		for(int sample_num = 0; sample_num<num_samples_for_half_period; sample_num++){
			*(audio_base + 2) = 16777215;
			*(audio_base + 3) = 16777215;
		}
		for(int sample_num = 0; sample_num<num_samples_for_half_period; sample_num++){
			*(audio_base + 2) = 0;
			*(audio_base + 3) = 0;
		}
		
    }
	
	return 0;
	
}