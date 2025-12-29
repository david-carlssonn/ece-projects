`timescale 1ns / 1ps

module register #(parameter WI = 2, WF = 10, WIO = 2, WFO = 30)
                   (input CLK, RST,
                    input signed [WI+WF-1:0] din,
                    output reg signed [WI+WF-1:0] q
    );
    always @(posedge CLK) begin
        if(RST) q <= 0;
        else    q <= din;
    end
endmodule