`timescale 1ns / 1ps


module fp_mult #(parameter WI1 = 4, WF1 = 16, WI2 = 4, WF2 = 16, WIO = WI1+WI2, WFO = WF1+WF2)
                    (input signed [WI1+WF1-1:0] in1,
                     input signed [WI2+WF2-1:0] in2,
                     output reg signed [WIO+WFO-1:0] out
                    );

    reg signed [((WI1+WI2)+(WF1+WF2))-1:0] product;
    
    always @* begin
        out = in1 * in2;
    end



endmodule
