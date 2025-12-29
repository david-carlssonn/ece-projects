`timescale 1ns / 1ps

module sos #(WIC = 2, WFC = 14, WI_IN = 2, WF_IN = 10, WII = 2, WFI = 30, SOS_NUM = 0, SOS_COEFFS = SOS_NUM * 6, NUM_TAPS = 6)
            (input CLK, rst,
             input signed [WI_IN+WF_IN-1:0] x,
             output reg signed [WI_IN+WF_IN-1:0] y,
             output next_pulse
    );
    reg signed [WIC+WFC-1:0] coeffs [0:23];
    
    initial $readmemb("sos_binary.txt", coeffs);
    
    wire signed [WI_IN+WF_IN-1:0] x_d [0:(NUM_TAPS >> 1)-2];
    wire signed [WII+WFI-1:0] y_d [0:(NUM_TAPS >> 1)-2];
    wire signed [WII+WFI-1:0] add [0:NUM_TAPS-3];
    wire signed [WII+WFI-1:0] mult [0:NUM_TAPS-2];
    wire signed [WII+WFI-1:0] y_ext;
    
    genvar i;
    //---------------------REGISTER GENERATION----------------------------
    generate
        for(i = 0; i < NUM_TAPS-2; i = i + 1) begin
            //For first register, always take x as input
            if(i == 0) register #(.WI(WI_IN), .WF(WF_IN))U000 (.CLK(CLK), .RST(rst), .din(rst ? 0:x), .q(x_d[i]));

            //Creates the rest of the registers for the feed forward side
            else if(i > 0 && i < (NUM_TAPS >> 1)-1) register #(.WI(WI_IN), .WF(WF_IN)) U001 (.CLK(CLK), .RST(rst), .din(rst ? 0:x_d[i-1]), .q(x_d[i]));
            
            //Creates first register for the feedback side and feedback output
            else if(i == (NUM_TAPS >> 1)-1) register #(.WI(WII), .WF(WFI), .WIO(WII), .WFO(WFI)) U101 (.CLK(CLK), .RST(rst), .din(rst ? 0:y_ext), .q(y_d[(i+1)-(NUM_TAPS >> 1)]));
            
            //Creates rest of registers for feedback side
            else register #(.WI(WII), .WF(WFI), .WIO(WII), .WFO(WFI)) U101 (.CLK(CLK), .RST(rst), .din(rst ? 0:y_d[i-(NUM_TAPS >> 1)]), .q(y_d[(i+1)-(NUM_TAPS >> 1)]));
        end
    endgenerate
    //--------------------------------------------------------------------
    //----------------------MULTIPLIER GENERATION-------------------------
    generate
        for(i = 0; i < NUM_TAPS-1; i = i + 1) begin
            //If first multiplier, take x and b0 as input
            if(i == 0) fp_mult #(.WI1(WIC), .WF1(WFC), .WI2(WI_IN), .WF2(WF_IN), .WIO(WII), .WFO(WFI)) 
                      U010(.in1(coeffs[i+SOS_COEFFS]), .in2(x), .out(mult[i]));
                      
            //Creates the rest of the multipliers for the feed forward side
            else if(i > 0 && i < NUM_TAPS >> 1) fp_mult #(.WI1(WIC), .WF1(WFC), .WI2(WI_IN), .WF2(WF_IN), .WIO(WII), .WFO(WFI)) 
                      U011(.in1(coeffs[i+SOS_COEFFS]), .in2(x_d[i-1]), .out(mult[i]));
            
            //Creates first multiplier for the feedback side
            else if(i == NUM_TAPS >> 1) fp_mult #(.WI1(WIC), .WF1(WFC), .WI2(WII), .WF2(WFI), .WIO(WII), .WFO(WFI))
                      U011(.in1(-coeffs[i+SOS_COEFFS + 1]), .in2(y_d[i-(NUM_TAPS >> 1)]), .out(mult[i]));
             
            //Creates the rest of the multipliers for feedback
            else fp_mult #(.WI1(WIC), .WF1(WFC), .WI2(WII), .WF2(WFI), .WIO(WII), .WFO(WFI))
                      U100(.in1(-coeffs[i+SOS_COEFFS + 1]), .in2(y_d[i-(NUM_TAPS >> 1)]), .out(mult[i]));
        end
    endgenerate
    //--------------------------------------------------------------------
    //------------------------ADDER GENERATION----------------------------
    generate
        for(i = 0; i < NUM_TAPS-2; i = i + 1) begin
            //First adder for feed forward takes mult[0] in and add[1] (Total FF sum)
            if(i == 0) fp_adder #(.WI1(WII), .WF1(WFI), .WI2(WII), .WF2(WFI), .WIO(WII), .WFO(WFI)) 
                       U110(.in1(mult[i]), .in2(add[i+1]), .out(add[i]), .OVF());
                       
            //Creates the rest of the adders for feed forward
            else if(i > 0 && i < (NUM_TAPS >> 1)-1) fp_adder #(.WI1(WII), .WF1(WFI), .WI2(WII), .WF2(WFI), .WIO(WII), .WFO(WFI)) 
                       U111(.in1(mult[i]), .in2(mult[i+1]), .out(add[i]), .OVF());
           
            //Creates first adder for feedback mult[3] and add[3] as inputs (mult[3] + mult[4] is total FB sum)
            else if(i == (NUM_TAPS >> 1)-1) fp_adder #(.WI1(WII), .WF1(WFI), .WI2(WII), .WF2(WFI), .WIO(WII), .WFO(WFI)) 
                       U0000(.in1(mult[i+1]), .in2(add[i+1]), .out(add[i]), .OVF());
            
            //Creates rest of adders for the feedback side
            else fp_adder #(.WI1(WII), .WF1(WFI), .WI2(WII), .WF2(WFI), .WIO(WII), .WFO(WFI)) 
                       U0010(.in1(0), .in2(mult[i+1]), .out(add[i]), .OVF());
        end
    endgenerate
    //--------------------------------------------------------------------
    //Final add to add FF and FB
    fp_adder #(.WI1(WII), .WF1(WFI), .WI2(WII), .WF2(WFI), .WIO(WII), .WFO(WFI)) 
                       U110(.in1(add[0]), .in2(add[2]), .out(y_ext), .OVF());
    always @(posedge CLK) begin
        y <= y_ext >>> (WFI-WF_IN); //Shift by 20 since Q(2.30) -> Q(2.10)
    end
    reg clear, clear_d;
    always @(posedge CLK) begin
        if(rst) begin
            clear <= 0;
            clear_d <= 0;
        end
        else begin
            clear_d <= clear;
            clear <= 1'b1;
        end
    end
    //Single cycle flag that fires right after reset
    assign next_pulse = (~clear_d) & clear;
endmodule