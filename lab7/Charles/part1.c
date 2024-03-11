
#include <stdbool.h>
#include <math.h>

#define FPGA_PIXEL_BUF_BASE		0x08000000
#define FPGA_PIXEL_BUF_END		0x0803FFFF
#define VGA_CONTROLLER_BASE 	0xff203020
#define NUM_PIXELS_IN_SCREEN 	76800 // 320px by 240px

// Utility Function Prototypes
void swap(int*, int*);
int abs(int);

// Drawing Function Prototpes
void drawIndividualPixel(int, int, short int);
void drawBresenhamLine(int, int, int, int, short int);
void clearWholeScreen();
void tracebackEraser(int);

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
	
	drawBresenhamLine(0, 0, 150, 150, 0x001F); // this line is blue 
	drawBresenhamLine(150, 150, 319, 0, 0x07E0); // this line is green 
	drawBresenhamLine(0, 239, 319, 239, 0xF800); // this line is red 
	drawBresenhamLine(319, 0, 0, 239, 0xF81F); // this line is pink
	
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
