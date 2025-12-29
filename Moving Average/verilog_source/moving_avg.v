`timescale 1ns / 1ps

module moving_avg #(parameter L = 4, WL = 4)
                   (input CLK, RST, valid,
                    input [WL-1:0] din,
                    output reg [WL-1:0] avg

    );
    
    
    integer frame = 0;
    reg [WL-1:0] window [L-1:0];
    reg [WL:0] sum, accum;
    reg [1:0] state;
    reg [1:0] count;
    localparam IDLE = 2'b00, START = 2'b01, AVG = 2'b10;
    
    
    always @* begin                                             //Combinational block to calculate sum
        accum = 0;
        for(frame=0 ; frame<=L-1; frame=frame+1)
            accum = accum + window[frame];       
    end
    always @(posedge CLK) begin
        if(RST) begin
            state <= IDLE;
            sum <= 0;
            accum <= 0;
            avg <= 0;
            count <= 0;
            for(frame=0; frame<=L-1; frame=frame+1) begin       //On RST, zero out memory
                window[frame] <= 1'b0;
            end
        end
        
        else begin
        
            case(state)
                IDLE:
                    if(valid) state <= START;
                
                START: begin
                    window[0] <= din;                           //Shift input into first frame
                    if(count < 1) count <= count + 1;           //Counter to ensure the stability of values
                    else begin
                        count <= 0;
                        state <= AVG;                           //After timer overflows, calculate sum and avg
                    end
                end
                   
                AVG: begin
                    sum <= accum;                               //Register accum so that its synchronous    
                    for(frame=1 ; frame<=L-1; frame=frame+1)
                        window[frame] <= window[frame-1];       //Shift values down the window
                        
                    avg <= sum >> $clog2(L);                    //Divide sum by L to calculate average
                    
                    state <= START;                             //Repeat
                end
                default: state <= IDLE;                
            endcase
        end
        
        
        
    end
    
endmodule
