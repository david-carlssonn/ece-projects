`timescale 1ns / 1ps


module fp_mult #(parameter WI1 = 4, WF1 = 16, WI2 = 4, WF2 = 16, WIO = WI1+WI2, WFO = WF1+WF2)
                    (input signed [WI1+WF1-1:0] in1,
                     input signed [WI2+WF2-1:0] in2,
                     output reg signed [WIO+WFO-1:0] out
                    );
    localparam integer signed SHIFT = (WF1+WF2)-WFO;
    wire signed [WI1+WF1 + WI2+WF2 -1:0] product = in1*in2;
    always @* begin
        //If the two fractional widths are greater than the output width shift right by the difference
        if(SHIFT > 0) out = product >>> SHIFT;
        //If the two fractional widths are less than the output width shift left by the difference
        else if (SHIFT < 0) out = product <<< (-SHIFT);
        //If fractional widths are the same as output width keep the same
        else out = product;
    end

endmodule