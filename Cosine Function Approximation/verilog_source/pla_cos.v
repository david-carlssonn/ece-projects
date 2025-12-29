`timescale 1ns / 1ps


module pla_cos #(parameter WI1 = 4, WF1 = 12, WI2 = 2, WF2 = 14, Widx = 6)
                (input CLK,
                 input signed [WI1+WF1-1:0] x,
                 output reg signed [WI2+WF2-1:0] y
                 );

    parameter seg_num = 8'd64, r_two_pi = 16'b0000001010001100;
    
    reg signed [2*WI1+2*WF1-1:0] coeffs; 
    reg signed [WI1+WF1-1:0] b, x_pipe, x_pipe2;
    reg signed [2*WI1+2*WF1-1:0] mult_ax;
    wire signed [2*WI1+2*WF1-1:0] mult_ax_full;
    wire signed [(2*WI1+1)+(2*WF1)-1:0] y_full;
    
    //Continuously refresh a and b every clock coeffs changes
    wire signed [15:0] a_lut = coeffs[31:16];
    wire signed [15:0] b_lut = coeffs[15:0];

    wire [Widx-1:0] index;
    wire [WI1+WI1+WF1+WF1-1:0] mul_index;
    wire [WI1+WF1-1:0] seg_size;
    wire [2*WI1+2*WF1-1:0] mul_index_full;

//Unsigned multiplier to handle index calculation   
//  assign seg_size = seg_num * r_two_pi;       // (64/2pi) = 1/seg_size    
    fp_umult #(.WI1(8), .WF1(0), .WI2(WI1), .WF2(WF1), .WIO(), .WFO())
                U0000(.in1(seg_num), .in2(r_two_pi), .out(seg_size));
                
//Unsigned multiplier to handle index calculation
//  assign mul_index = (seg_size * x) >> 24;    // (x/seg_size) = LUT index
    fp_umult #(.WI1(WI1), .WF1(WF1), .WI2(WI1), .WF2(WF1), .WIO(), .WFO())
                U0001(.in1(seg_size), .in2(x), .out(mul_index_full));

    //Shifting over 24 to drop frac bits and keep integer
    assign mul_index = mul_index_full >> 24;
    //Index 0-63
    assign index = mul_index[5:0];
    
    
    reg signed [2*WI1+2*WF1-1:0] coeff_LUT [(2**Widx)-1:0];
    initial $readmemb("coeffROM.mem", coeff_LUT);
    
//  mult_ax <= (a_lut*x_pipe2) >>> 12;
    fp_mult #(.WI1(WI1), .WF1(WF1), .WI2(WI1), .WF2(WF1), .WIO(), .WFO())
                U0010(.in1(a_lut), .in2(x_pipe2), .out(mult_ax_full));
                

//  y <= (mult_ax + b) << 2;
    fp_addr #(.WI1(2*WI1), .WF1(WF1), .WI2(WI1), .WF2(WF1), .WIO(), .WFO())
                U0011(.in1(mult_ax), .in2(b), .out(y_full), .OVF());
                
    always @(posedge CLK) begin
        x_pipe <= x;
        x_pipe2 <= x_pipe;
        coeffs <= coeff_LUT[index];
        b <= b_lut;
        mult_ax <= mult_ax_full >>> 12; //Shift 12 to right to revert back to Q(4.12)
        y <= y_full << 2;               //Shift left 2 to convert to Q(2.14)
    end
    
endmodule
