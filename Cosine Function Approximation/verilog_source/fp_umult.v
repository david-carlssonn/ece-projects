`timescale 1ns / 1ps

//Unsigned multiplier
module fp_umult #(parameter WI1 = 4, WF1 = 16, WI2 = 4, WF2 = 16, WIO = WI1+WI2, WFO = WF1+WF2)
                    (input [WI1+WF1-1:0] in1,
                     input [WI2+WF2-1:0] in2,
                     output reg [WIO+WFO-1:0] out
                    );
    
    always @* begin
        out = in1 * in2;
    end



endmodule