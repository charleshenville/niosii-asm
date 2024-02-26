#include <stdlib.h>
#define delay_data_size 3200 // Delay 0.4s * sample rate 8kHz

int main(void) {

    volatile int * audio_base = (volatile int *) 0xFF203040;

    const float damping_coefficient = 0.2;

    int **delay_bufs = (int **)malloc(delay_data_size * sizeof(int *));
    int delay_list_position = 0;

    for(int i = 0; i < delay_data_size; i++){ // Allocate all null memory for buffer

        int *null_sample = (int *)malloc(2 * sizeof(int));
        null_sample[0] = 0;
        null_sample[1] = 0;
        delay_bufs[i] = null_sample;

    }

    while (1) {

        while(delay_list_position < delay_data_size){ // read from the buffer and write to the list

            if((*(audio_base + 1) & 0x0000ffff) > 0){

                // Get the output samples from input and prev. output
                int left_sample = *(audio_base + 2) + delay_bufs[delay_list_position][0];
                int right_sample = *(audio_base + 3) + delay_bufs[delay_list_position][1];

                // store samples in the output fifo via data channels
                *(audio_base + 2) = left_sample;
                *(audio_base + 3) = right_sample;

                // store our damped samples into the buffer list for next time
                delay_bufs[delay_list_position][0] = left_sample * damping_coefficient;
                delay_bufs[delay_list_position][1] = right_sample * damping_coefficient;

                delay_list_position++;

            }

        }

        delay_list_position = 0;

    }

    // memory cleanup
    for (int i = 0; i < delay_data_size; i++) {

        free(delay_bufs[i]);

    }
    free(delay_bufs);

    return 0;

}
