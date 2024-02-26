#include <stdlib.h>

struct audio_t {
	volatile unsigned int control; // The control/status register
	volatile unsigned char RARC; // the 8 bit RARC register
	volatile unsigned char RALC; // the 8 bit RALC register
	volatile unsigned char WSRC; // the 8 bit WSRC register
	volatile unsigned char WSLC; // the 8 bit WSLC register
	volatile unsigned int ldata; // the 32 bit (really 24) left data register
	volatile unsigned int rdata; // the 32 bit (really 24) right data register
};

struct node{ //simple node structure in a linked list
	int value;
	struct node* next;
};

void enqueue(struct node* head,int NewValue); //adds node to back of queue
struct node* dequeue(struct node* head); //removes node from front of queue

int main(){
	struct audio_t *const audiop = ((struct audio_t *) 0xff203040); //intialize audio port address
	struct node* head = (struct node*) malloc(sizeof(struct node)); //initalize head of queue
	
	head->value=0;
	head->next=NULL;
	
	int left; //LC and RC data values
	int right;
		
		
	for(int i = 0; i < 3199; i++){ //intialize delay linked list with .4s delay
		enqueue(head,0);
	}
	
	while(1){
		if(audiop->RARC){ //check to see if another input is available
			left = audiop->ldata; //store input into respectice channels
			right = audiop->rdata;
			
			left += (0.2*head->value); //add echo to output with damping coefficient 0.2
			right += (0.2*head->value);
			
			audiop->ldata = left; //send LC and RC to output
			audiop->rdata = right;
			
			enqueue(head,left); //add new output to echo queue
			head = dequeue(head); //remove head to be ready for next output
		}
	}
	
	while(head != NULL){ //clear allocated memory
		head = dequeue(head);
	}
	
	return 0;
}

void enqueue(struct node* head,int NewValue){
	struct node* NewNode = (struct node*) malloc(sizeof(struct node)); //intialize a new Node
	NewNode->value=NewValue;
	NewNode->next=0;

	struct node* temp = head;
	while(temp->next != NULL) temp = temp->next; //loop to end of list

	temp->next = NewNode; //add new node to end of list
}

struct node* dequeue(struct node* head){//frees head and returns pointer to the second element which is the new head
	struct node* newHead = head->next; 
	free(head);
	return newHead;
}