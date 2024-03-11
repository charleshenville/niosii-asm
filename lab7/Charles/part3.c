
#include <stdbool.h>
#include <stdlib.h>

#define FPGA_PIXEL_BUF_BASE		0x08000000
#define FPGA_PIXEL_BUF_END		0x0803FFFF
#define VGA_CONTROLLER_BASE 	0xff203020
#define NUM_LINES 				8
#define NUM_PIXELS_IN_SCREEN 	76800 // 320px by 240px

// Utility Function Prototypes
void swap(int*, int*);
int abs(int);
void waitForVsync();
short int hueToRGB565(float);

// Drawing Function Prototpes
void drawIndividualPixel(int, int, short int);
void drawBresenhamLine(int, int, int, int, short int);
void drawBox(int, int, short int);
void clearWholeScreen();
void tracebackErase();

// Struct and and 2D array of them that will define the lines we erase in
// our traceback erase.
typedef struct nonblackLine {
	int x0;
	int y0;
	int x1;
	int y1;
} nonblackLine;
typedef struct nonblackPixel {
	int x;
	int y;
} nonblackPixel;

// Struct to hold the physics-related data
typedef struct physicalState {
	int positionX;
	int positionY;
	int velocityX;
	int velocityY;
} physicalState;

// Allocate an array of lines with max size of NUM_LINES
nonblackLine nonblackLines [NUM_LINES];
nonblackPixel nonblackPixels [NUM_LINES];
physicalState physicalStates [NUM_LINES];

// Global telling us the starting address of the Pixel Buffer
int STARTING_BUFFER_ADDRESS;

int main(void) {
	
	// Seed the random number generator
	srand(time(NULL));
	
	volatile int *vgaCtlPtr = (int *)VGA_CONTROLLER_BASE;
	STARTING_BUFFER_ADDRESS = *vgaCtlPtr;
	
	clearWholeScreen();
	
	// Define parameters to make the line bounce with constant velocity.
	int maxY = 240;
	int maxX = 320;
	
	short int colourVector [NUM_LINES];
	float hue;
	// Set "dummy" previous lines so that we can "erase" it on the
	// very first iteration of the infinite while loop below
    for (int i = 0; i < NUM_LINES; i++) {
        hue = (float)i / NUM_LINES;
        colourVector[i] = hueToRGB565(hue);
		
		nonblackLines[i].x0 = 0;
		nonblackLines[i].y0 = 0;
		nonblackLines[i].x1 = 0;
		nonblackLines[i].y1 = 0;
		nonblackPixels[i].x = 1;
		nonblackPixels[i].y = 1;
		
		// Also, set random initial values for position and velocity.
		physicalStates[i].positionX = rand() % (maxX-2)+1;
		physicalStates[i].positionY = rand() % (maxY-2)+1;
		physicalStates[i].velocityX = rand() % 2;
		physicalStates[i].velocityY = rand() % 2;
		
		if (physicalStates[i].velocityX == 0) physicalStates[i].velocityX = -1;
		if (physicalStates[i].velocityY == 0) physicalStates[i].velocityY = -1;
	}
	
	// Infinite loop to perpetually bounce the line up and down
	while(1){
		// Erase the line we drew in the last iteration of the loop.
		tracebackErase();
		
		// Shift all boxes by velocity
		for (int i = 0; i < NUM_LINES; i++){
			// Ensure we do not go out of bounds on the next iteration.
			if (physicalStates[i].positionX == maxX - 1){
				physicalStates[i].velocityX = -1;
			} else if (physicalStates[i].positionX == 1) {
				physicalStates[i].velocityX = 1;
			}
			if (physicalStates[i].positionY == maxY - 1){
				physicalStates[i].velocityY = -1;
			} else if (physicalStates[i].positionY == 1) {
				physicalStates[i].velocityY = 1;
			}
			physicalStates[i].positionX += physicalStates[i].velocityX;
			physicalStates[i].positionY += physicalStates[i].velocityY;
		}
		// Connect all of the boxes
		for (int i = 1; i < NUM_LINES; i++){
			// Draw the coloured line
			drawBresenhamLine(physicalStates[i-1].positionX, 
							  physicalStates[i-1].positionY, 
							  physicalStates[i].positionX, 
							  physicalStates[i].positionY, 
							  colourVector[i]);
			// Draw the box
			drawBox(physicalStates[i].positionX, physicalStates[i].positionY, colourVector[i]);
			// Document the defining characteristics of the current line.
			nonblackLines[i].x0 = physicalStates[i-1].positionX;
			nonblackLines[i].x1 = physicalStates[i].positionX;
			nonblackLines[i].y0 = physicalStates[i-1].positionY;
			nonblackLines[i].y1 = physicalStates[i].positionY;
			// Same for pixels
			nonblackPixels[i].x = physicalStates[i].positionX;
			nonblackPixels[i].y = physicalStates[i].positionY;
		}
		// Draw the coloured line connecting the first and last
		drawBresenhamLine(physicalStates[NUM_LINES-1].positionX, 
						  physicalStates[NUM_LINES-1].positionY, 
						  physicalStates[0].positionX, 
						  physicalStates[0].positionY, 
						  colourVector[0]);
		// Draw the box
		drawBox(physicalStates[0].positionX, physicalStates[0].positionY, colourVector[0]);
		// Document the defining characteristics of the current line.
		nonblackLines[0].x0 = physicalStates[NUM_LINES-1].positionX;
		nonblackLines[0].x1 = physicalStates[0].positionX;
		nonblackLines[0].y0 = physicalStates[NUM_LINES-1].positionY;
		nonblackLines[0].y1 = physicalStates[0].positionY;
		// Same for pixels
		nonblackPixels[0].x = physicalStates[0].positionX;
		nonblackPixels[0].y = physicalStates[0].positionY;
		
		// Wait for 1/60th of a second (usually) to draw the next frame.
		waitForVsync();
		// Get the new back buffer address to write to
		STARTING_BUFFER_ADDRESS = *(vgaCtlPtr);
	}
	
	return 0;
	
}

// Function to convert a hue to an R(5)G(6)B(5) bit scheme
short int hueToRGB565(float hue) {

    // Declare variables to store red, green, and blue components (initially floats for calculations)
    float r, g, b;

    // Calculate the sector of the color wheel (shown in the case statement below)
    int sector = floor(hue * 6);

    // Calculate the fractional part to transition
    float f = hue * 6 - sector;
    // Invert the fractional part in some cases
    float nf = 1 - f;

    // Determine the RGB values based on the sector
    switch (sector) {
        case 0:  // Red
            r = 1.0; g = f; b = 0.0; break;
        case 1:  // Red -> Green
            r = nf; g = 1.0; b = 0.0; break;
        case 2:  // Green
            r = 0.0; g = 1.0; b = f; break;
        case 3:  // Green -> Blue
            r = 0.0; g = nf; b = 1.0; break;
        case 4:  // Blue
            r = f; g = 0.0; b = 1.0; break;
        default: // Blue -> Red
            r = 1.0; g = 0.0; b = nf; break;
    }

    // Scale the RGB values to fit 5, 6, 5 bit col channels
    r *= 31;
    g *= 63;
    b *= 31;

    // Combine the RGB values into a single RGB565 value
    return ((int)r << 11) | ((int)g << 5) | (int)b;
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

// Erase all the lines and boxes we drew
void tracebackErase(){
	
	for (int lineIndex = 0; lineIndex < NUM_LINES; lineIndex++){
		nonblackLine cLine = nonblackLines[lineIndex];
		nonblackPixel cPx = nonblackPixels[lineIndex];
		drawBresenhamLine(cLine.x0, cLine.y0, cLine.x1, cLine.y1, 0);
		drawBox(cPx.x, cPx.y, 0);
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

// Draws a nxn box centered at the pixel x,y
void drawBox(int x, int y, short int colour){
	int n = 3;
	int shift = floor(n/2);
	for(int i = 0; i < n; i++){
		for(int j = 0; j < n; j++){
			drawIndividualPixel(x+(i-shift), y+(j-shift), colour);
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
