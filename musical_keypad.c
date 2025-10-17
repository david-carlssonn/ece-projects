#include <avr/io.h>
#define F_CPU 16000000UL
#include <math.h>
#include <util/delay.h>
//OCRA - Frequency
//OCRB - Duty Cycle
void generate_PWM(){
	TCCR0A |= (1 << WGM01);		//CTC Mode
	TCCR0B |= (1 << CS02) | (1 << CS00);	//1024 prescaler
}


void stopPWM(){
	
	//Disables timer (Turns off PWM)
	TCCR0B &= ~(1 << CS02);
	TCCR0B &= ~(1 << CS00);
	
	//Set outputs for audio to logic low (turn off sound)
	PORTC &= ~(1 << PORTC4);
	PORTC &= ~(1 << PORTC5);
}


float calc_timeunits(int index){
	float period;
	
	//(1/(440*(2^(1/12))^x)
	period = 1.0/(440.0*(pow(pow(2.0, (1.0/12.0)), index)));
	
	//Time units = (orig time units * period you want) / (prescaler * 16 microseconds)
	return ((256.0*period) / (0.016384));
}


int keypad_scan() {
	
	int key_pad[4][4] = {		//Keypad initialization
			{0, 1, 2, 3},
			{4, 5, 6, 7},
			{8, 9, 10, 11},
			{12, 13, 14, 15}
		};


	int row_num, col_num;
	
	for(row_num = 0; row_num < 4; row_num++) {	//Row scan


		//Resets rows to logic high
		PORTD |= (1<<PORTD4) | (1<<PORTD5) | (1<<PORTD6) | (1<<PORTD7);


		//Sets each row one at a time to logic low to isolate each row
		PORTD &= ~(1<<(PORTD4 + row_num));
				
		for(col_num = 0; col_num < 4; col_num++) {	//Column scan
					
			//If the button that is being looked at is pressed...
			if(!(PINB & (1 << col_num))){


				//Return index 0-15
				return key_pad[row_num][col_num];
				}
			}
		}
		return -1;	//If no button press is detected during a whole cycle return -1
}


int main(void)
{
	int button;
	DDRC |= (1 << DDRC4) | (1 << DDRC5);	//Set audio jack as output
	
//-----------------------KEYPAD INITIALIZATION--------------------
	//Setting rows to output
	DDRD |= (1<<DDRD4) | (1<<DDRD5) | (1<<DDRD6) | (1<<DDRD7);


	//Setting cols to input
	DDRB &= ~(1<<DDRB0); DDRB &= ~(1<<DDRB1); 
	DDRB &= ~(1<<DDRB2); DDRB &= ~(1<<DDRB3);
	
	//Setting cols to pull up input
	PORTB |= (1<<PORTB0) | (1<<PORTB1) | (1<<PORTB2) | (1<<PORTB3);


	//Setting rows to output logic high
	PORTD |= (1<<PORTD4) | (1<<PORTD5) | (1<<PORTD6) | (1<<PORTD7);
//--------------------------------------------------------------------


    while (1) 
    {
		button = keypad_scan();	//Store index of button into button variable
		
		if(button >= 0 && button <= 15){ //If button press is detected...
		generate_PWM();		 //Generate PWM when a button press is detected
		OCR0A = calc_timeunits(button);	 //Calculate time units based on index
		OCR0B = (OCR0A / 2.0);		//Calculates 50% duty cycle based on period
				
		//SET LOGIC HIGH
		PORTC |= (1 << PORTC4) | (1 << PORTC5);
		
		while (!(TIFR0 & (1 << OCF0B)));	//Wait until ORC0B is hit
		TIFR0 |= (1 << OCF0B);				//Reset B flag
		
		//SET LOGIC LOW
		PORTC &= ~(1 << PORTC4); 
		PORTC &= ~(1 << PORTC5);
		
		while (!(TIFR0 & (1 << OCF0A)));	//Wait until OCR0A is hit
		TIFR0 |= (1 << OCF0A);		//Reset A flag
		}
		else {					//If button press returns -1 (no button press)
			stopPWM();			//Stop the PWM so there is no excess sound
		}


    }
}
