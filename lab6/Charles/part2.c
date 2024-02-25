int main(void) {
	
    volatile int * audio_base = 0xFF203040;

    int left_channel, right_channel, fifo;

    while (1) {
		
        fifo = *(audio_base + 1); // read the audio port fifospace register
        if ((fifo & 0x0000FFFF) > 0) // check left, right fifo for data
			
        {
			
            // load single sample from either channel
            int left_channel_sample = *(audio_base + 2);
            int right_channel_sample = *(audio_base + 3);
			
            // store samples in the output fifo via data channels
            *(audio_base + 2) = left_channel_sample;
            *(audio_base + 3) = right_channel_sample;
			
        }
		
    }
	
}