`timescale 1ns / 1ps

module sos_cascade #(parameter WIC = 2, WFC = 14, WI_IN = 2, WF_IN = 10, WI_OUT = 2, WF_OUT = 10, G_NUM = 5, SOS_NUM = 4)
                   (input CLK, rst,
                   input signed [WI_IN+WF_IN-1:0] signal,
                   output reg signed [WI_OUT+WF_OUT-1:0] filtered
        );
    wire signed [WI_OUT+WF_OUT-1:0] node [0:G_NUM-1];
    wire signed [WI_OUT+WF_OUT-1:0] sos_out [0:SOS_NUM-1];    
    reg signed [WIC+WFC-1:0] g_vals [0:G_NUM-1];
    
    wire pulse [0:SOS_NUM-1];
    wire rst_local [0:SOS_NUM-1];
    
    initial $readmemb("g_binary.txt", g_vals);
    
    //Tie first sos to global rst
    assign rst_local[0] = rst;
    
    //Scale the input by g0
    fp_mult #(.WI1(WIC), .WF1(WFC), .WI2(WI_OUT), .WF2(WF_OUT), .WIO(WI_OUT), .WFO(WF_OUT)) 
                      U010(.in1(g_vals[0]), .in2(signal), .out(node[0]));
    genvar i;  
    generate
        for(i = 0; i < SOS_NUM-1; i = i + 1) begin
            //Previous pulse resets next sos
            if(i > 0) assign rst_local[i] = rst | pulse[i-1];
            
            //sos[i] produces a 1-cycle pulse after rst_local[i] deasserts
            sos #(.SOS_NUM(i)) U00 (.CLK(CLK), .rst(rst_local[i]), .x(node[i]), .y(sos_out[i]), .next_pulse(pulse[i]));
            
            //Multipliers inbetween sos for scaling
            fp_mult #(.WI1(WIC), .WF1(WFC), .WI2(WI_OUT), .WF2(WF_OUT), .WIO(WI_OUT), .WFO(WF_OUT)) 
                      U011(.in1(g_vals[i+1]), .in2(sos_out[i]), .out(node[i+1]));
        end
        //Use previous pulse for last sos to reset
        assign rst_local[SOS_NUM-1] = rst | pulse[SOS_NUM-2];
        sos #(.SOS_NUM(SOS_NUM-1)) U01 (.CLK(CLK), .rst(rst_local[SOS_NUM-1]), .x(node[SOS_NUM-1]), .y(sos_out[SOS_NUM-1]), .next_pulse(pulse[SOS_NUM-1]));
    endgenerate
        //Last multiply for g[4]
        fp_mult #(.WI1(WIC), .WF1(WFC), .WI2(WI_OUT), .WF2(WF_OUT), .WIO(WI_OUT), .WFO(WF_OUT)) 
                      U111(.in1(g_vals[G_NUM-1]), .in2(sos_out[SOS_NUM-1]), .out(node[G_NUM-1]));
    always @(posedge CLK) begin
        if(rst) filtered <= 0;
        else filtered <= node[G_NUM-1];
    end
endmodule
