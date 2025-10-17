`timescale 1ns / 1ps


module alarm(input CLK100MHZ, btnC, btnU, btnD, btnL, btnR,
             output reg [3:0] alarm_hourten = 1,  alarm_hour = 2, alarm_minten = 5, alarm_min = 9,
             output reg alarm_mode = 1'b0,
             output reg btnC_debounced
);

reg [6:0] seg;
reg [19:0] debounce_count;
reg btnL_debounced, btnR_debounced, btnU_debounced, btnD_debounced;

always@(posedge CLK100MHZ) begin
        if(debounce_count < 1000000)           //10ms timer that checks only 1 input of each button
            debounce_count <= debounce_count + 1;
        else begin
            debounce_count <= 0;
            btnC_debounced <= btnC;
            btnR_debounced <= btnR;
            btnL_debounced <= btnL;
            btnU_debounced <= btnU;
            btnD_debounced <= btnD;
        end
end

always@(posedge CLK100MHZ) begin
    if(btnC_debounced) begin
        alarm_mode <= ~alarm_mode;
    end
    else if(alarm_mode) begin
    
        if(btnR_debounced) begin            //Right button increments minutes
            if(alarm_min < 9) begin         //If an[0] hasn't overflowed, increment it
                alarm_min <= alarm_min + 1;
            end else begin
                alarm_min <= 0;             //If it has set it to 0
                
                if(alarm_minten < 5) begin //If an[1] hasn't overflowed, increment it
                    alarm_minten <= alarm_minten + 1;
                end else begin
                    alarm_minten <= 0;      //If it has set it to 0
                end
            end
        end

        else if(btnL_debounced) begin       //Left button decrements minutes
            if(alarm_min > 0) begin         //If an[0] hasnt hit 0 yet, decrement it
               alarm_min <= alarm_min - 1;
            end else begin                  //If it has then check an[1] to see if it hit 0
                    if(alarm_minten > 0) begin  //If an[1] hit 0, decrement and set an[0] back up to 9
                        alarm_minten <= alarm_minten - 1;
                        alarm_min <= 9;
                    end else begin          //If an[1] goes past 0, then we are decrementing an hour
                            alarm_minten <= 5;  //And setting an[1] and an[0] to 5 and 9
                            alarm_min <= 9;
                    end
               end
        end
        
       else if(btnU_debounced) begin    //Up button increments hours
            if(alarm_hour < 9) begin    //If an[2] hasn't overflowed, increment it
               alarm_hour <= alarm_hour + 1;
            end else begin
                    alarm_hour <= 0;    //If an[2] overflows, set to 0
                    if(alarm_hourten < 1) begin //If an[3] isnt 1 yet, increment it after an[2] overflows
                        alarm_hourten <= alarm_hourten + 1;
                    end else begin      //Error checking
                            alarm_hourten <= 0;
                            alarm_hour <= 1;
                        end
               end
           if(alarm_hourten == 1 && alarm_hour > 2) begin //Catches 12:00 -> 01:00 overflow  
              alarm_hourten <= 0;
              alarm_hour <= 1;
           end   
       end
       
       else if(btnD_debounced) begin    //Down button decrements hours
            if(alarm_hour > 0) begin    //If an[2] hasn't hit 0 yet, decrement it
               alarm_hour <= alarm_hour - 1;
            end else begin
                    if(alarm_hourten > 0) begin //If it has then check an[3] to see if it hit 0
                        alarm_hourten <= alarm_hourten - 1; //If an[3] is still > 0 decrement and set an[2] to 9
                        alarm_hour <= 9;
                    end else begin              //Once an[3] and an[2] hit 0 (going under 01:00)
                            alarm_hourten <= 1; //Wrap alarm back around to 12:00
                            alarm_hour <= 2;
                        end
                    end
                end
            end           
        end
endmodule
