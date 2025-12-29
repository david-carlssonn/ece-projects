`timescale 1ns / 1ps

module register #(parameter WI = 2, WF = 10)
                   (input CLK,
                    input signed [WI+WF-1:0] din,
                    output reg signed [WI+WF-1:0] q
    );
    always @(posedge CLK) begin
        q <= din;
    end
endmodule