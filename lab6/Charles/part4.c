#include <stdlib.h>
#define delay_data_size 3200 // Delay 0.4s * sample rate 8kHz

int main(void) {
	
    volatile int * audio_base = (volatile int *) 0xFF203040;
	
	const float damping_coefficient = 0.2;
	
	int ** delay_list = (int **)malloc(delay_data_size * sizeof(int *));
	int ** delay_bufs = (int **)malloc(delay_data_size * sizeof(int *));
	int delay_list_position = 0;
	
	for(int i = 0; i < delay_data_size; i++){ // Allocate all null memory for buffers

		int *null_sample = (int *)malloc(2 * sizeof(int));
		null_sample[0] = 0;
		null_sample[1] = 0;
		delay_bufs[i] = null_sample;
		delay_list[i] = null_sample;

	}

	while (1) {
		
		while(delay_list_position < delay_data_size){ // read from the buffer and write to the list
						
			// load single sample from either channel
			delay_list[delay_list_position][0] = *(audio_base + 2);
			delay_list[delay_list_position][1] = *(audio_base + 3);
			
			// Get the output samples
			int left_sample = delay_list[delay_list_position][0] + delay_bufs[delay_list_position][0];
			int right_sample = delay_list[delay_list_position][1] + delay_bufs[delay_list_position][1];
			
			// store samples in the output fifo via data channels
			*(audio_base + 2) = left_sample;
			*(audio_base + 3) = right_sample;
			
			// store our damped samples into the buffer list
			int *to_buffer = (int *)malloc(2 * sizeof(int));
			to_buffer[0] = left_sample;
			to_buffer[1] = right_sample;
			to_buffer[0] *= damping_coefficient;
			to_buffer[1] *= damping_coefficient;
			
			free(delay_bufs[delay_list_position]); // free up what's in buffer
			delay_bufs[delay_list_position] = to_buffer; // replacing it with our new samples
			
			delay_list_position++;
			
		}
		
		delay_list_position = 0;
		
    }
	
	// memory cleanup
	for (int i = 0; i < delay_data_size; i++) {
		
		free(delay_list[i]);
		free(delay_bufs[i]);
		
	}
	free(delay_list);
	free(delay_bufs);
	
	return 0;
	
}