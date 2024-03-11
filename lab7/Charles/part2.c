
#include <stdbool.h>
#include <math.h>

#define FPGA_PIXEL_BUF_BASE		0x08000000
#define FPGA_PIXEL_BUF_END		0x0803FFFF
#define VGA_CONTROLLER_BASE 	0xff203020
#define NUM_PIXELS_IN_SCREEN 	76800 // 320px by 240px

// Utility Function Prototypes
void swap(int*, int*);
int abs(int);
void waitForVsync();

// Drawing Function Prototpes
void drawIndividualPixel(int, int, short int);
void drawBresenhamLine(int, int, int, int, short int);
void clearWholeScreen();
void tracebackErase(int);

// Struct and and 2D array of them that will define the lines we erase in
// our traceback erase.
typedef struct nonblackLine {
	int x0;
	int y0;
	int x1;
	int y1;
} nonblackLine;

// Allocate an array of pixels with max size of the entire screen (320x240)
nonblackLine nonblackLines [NUM_PIXELS_IN_SCREEN];

// Global telling us the starting address of the Pixel Buffer
int STARTING_BUFFER_ADDRESS;

int main(void) {
	
	volatile int *vgaCtlPtr = (int *)VGA_CONTROLLER_BASE;
	STARTING_BUFFER_ADDRESS = *vgaCtlPtr;
	
	clearWholeScreen();
	
	// We're only drawing one line.
	int numlines = 1;
	
	// Define parameters to make the line bounce with constant velocity.
	int currentY = 0;
	int yStep = 1;
	int maxY = 240;
	
	// Set a "dummy" previous line so that we can "erase" it on the
	// very first iteration of the infinite while loop below
	nonblackLines[0].x0 = 0;
	nonblackLines[0].y0 = 0;
	nonblackLines[0].x1 = 320;
	nonblackLines[0].y1 = 0;
	
	// Infinite loop to perpetually bounce the line up and down
	while(1){
		// Ensure we do not go out of bounds on the next iteration.
		if (currentY==maxY && yStep == 1){
			yStep = -1;
		} else if (currentY==0 && yStep == -1){
			yStep = 1;
		}
		
		// Wait for 1/60th of a second (usually) to draw the next frame.
		waitForVsync();
		// Erase the line we drew in the last iteration of the loop.
		tracebackErase(numlines);
		
		// Set the horizontal line we are currently drawing for next time when we
		// want to erase it.
		nonblackLines[0].y0 = currentY;
		nonblackLines[0].y1 = currentY;
		
		// Draw the white horizontal line
		drawBresenhamLine(0, currentY, 320, currentY, 0xFFFF);
		currentY+=yStep;
	}
	
	return 0;
	
}

// Finds the absolue value of an int
int abs(int in){
	if (in>0) return in;
	return (0-in);
}

// Swaps two ints
void swap(int *a, int*b){
	int temp = *a;
	*a = *b;
	*b = temp;
}

void waitForVsync(){

	volatile int *vgaCtlPtr = (volatile int*)VGA_CONTROLLER_BASE;
	int status;
	*vgaCtlPtr = 1; // 1->Front Buffer Address. Kickstarts our swap/rendering process
	
	// Poll status bit for a 0
	status = *(vgaCtlPtr + 3);
	while ((status & 0x01)!=0){
		status = *(vgaCtlPtr + 3);
	}
		
}

// Erase all the lines we drew
void tracebackErase(int numLines){
	
	for (int lineIndex = 0; lineIndex < numLines; lineIndex++){
		nonblackLine cLine = nonblackLines[lineIndex];
		drawBresenhamLine(cLine.x0, cLine.y0, cLine.x1, cLine.y1, 0);
	}
	
}

// Draws just one pixel to the appropriate frame buffer.
void drawIndividualPixel(int x, int y, short int colour){
	volatile short int *pixelAddress;
	pixelAddress = (int *) (STARTING_BUFFER_ADDRESS + (y << 10) + (x << 1)); 
	*pixelAddress = colour;
}

// Writes black to every pixel in the pixel buffer
void clearWholeScreen(){
	
	for(int x = 0; x < 320; x++){ // 320px
		for(int y = 0; y < 240; y++) { // by 240px
			drawIndividualPixel(x, y, 0); // draw a black pixel
		}
	}

}

// Draws a line between the two points specified on screen. 
void drawBresenhamLine(int x0, int y0, int x1, int y1, short int colour){
	
	bool isSteep = abs(x0-x1) < abs(y0-y1);
	
	if(isSteep){
		swap(&x0, &y0);
		swap(&x1, &y1);
	}
	if(x0>x1){
		swap(&x0, &x1);
		swap(&y0, &y1);
	}
	
	int dx = x1 - x0;
	int dy = abs(y1 - y0);
	int error = -dx/2;
	
	int moveY = y1>y0 ? 1 : -1;
	
	int y = y0;
	int x = x0;
	
	while(x<=x1) {
		
		if (isSteep) drawIndividualPixel(y,x, colour);
		else drawIndividualPixel(x,y,colour);
		
		error = error + dy;
		if (error > 0){
			y = y + moveY;
			error = error - dx;
		}
		
		x++;
		
	}

}
