`timescale 1ns / 1ps


module cordic_stable #(parameter WL = 10, WI1 = 2, WF1 = 8, WI2 = 2, WF2 = 14, WL_I = 32, WIO = 1, WFO = 9)
               (input CLK, RST, start,
                input signed [WL-1:0] angle,
                output reg signed [WIO+WFO-1:0] sine, cosine,
                output reg done
                );
    parameter SIZE = 9;
    parameter signed pi_2 = 10'd256, pi = 10'd512;
    reg signed [WI2+WF2-1:0] K_fp = 16'd9950; //K = 0.60725293 w/ WF=14
    reg signed [WI2+WF2-1:0] x, y;
    reg signed [WL-1:0] z;
    wire [WL-1:0] z_next_gt, z_next_lt;
    wire [WL-1:0] z_norm_q2, z_norm_q3;
    integer i;
    reg signed [WL-1:0] atan_table [SIZE:0];
    wire [WL_I-1:0] i_next;
    wire [WI2+WF2-1:0] x_next_gt, y_next_gt, x_next_lt, y_next_lt;
    wire OVF;
    
    initial $readmemb ("arctan_LUT.txt", atan_table);
    
    //Fixed point adder for i to keep track of iterations (i=i+1)
    fp_adder #(.WI1(WL_I), .WF1(0), .WI2(WL_I), .WF2(0), .WIO(WL_I), .WFO(0))
              U0000(.in1(i), .in2(32'd1), .out(i_next), .OVF(OVF));
    
    //Fixed point adder for when z > 0 calculate x --> (x_next_gt = x - (y >>> i))         
    fp_adder #(.WI1(WI2), .WF1(WF2), .WI2(WI2), .WF2(WF2), .WIO(), .WFO())
              U0001(.in1(x), .in2(-(y >>> i)), .out(x_next_gt), .OVF(OVF));
    //Fixed point adder for when z > 0 calculate y --> (y_next_gt = y + (x >>> i))  
    fp_adder #(.WI1(WI2), .WF1(WF2), .WI2(WI2), .WF2(WF2), .WIO(), .WFO())
              U0010(.in1(y), .in2(x >>> i), .out(y_next_gt), .OVF(OVF));
    //Fixed point adder for when z > 0 calculate z --> (z_next_gt = z - atan_table[i])
    fp_adder #(.WI1(WL), .WF1(0), .WI2(WL), .WF2(0), .WIO(), .WFO())
              U0011(.in1(z), .in2(-atan_table[i]), .out(z_next_gt), .OVF(OVF));
    
    
    //Fixed point adder for when z < 0 calculate x --> (x_next_lt = x + (y >>> i))          
    fp_adder #(.WI1(WI2), .WF1(WF2), .WI2(WI2), .WF2(WF2), .WIO(), .WFO())
              U0100(.in1(x), .in2(y >>> i), .out(x_next_lt), .OVF(OVF));
    //Fixed point adder for when z < 0 calculate y --> (y_next_lt = y - (x >>> i)) 
    fp_adder #(.WI1(WI2), .WF1(WF2), .WI2(WI2), .WF2(WF2), .WIO(), .WFO())
              U0101(.in1(y), .in2(-(x >>> i)), .out(y_next_lt), .OVF(OVF));
    //Fixed point adder for when z < 0 calculate z --> (z_next_lt = z + atan_table[i])          
    fp_adder #(.WI1(WL), .WF1(0), .WI2(WL), .WF2(0), .WIO(), .WFO())
              U0110(.in1(z), .in2(atan_table[i]), .out(z_next_lt), .OVF(OVF));
    
    //Fixed point adder to normalized angle from Q2 back to Q1/Q4          
    fp_adder #(.WI1(WL), .WF1(0), .WI2(WL), .WF2(0), .WIO(), .WFO())
              U0111(.in1(angle), .in2(-pi), .out(z_norm_q2), .OVF(OVF));
    //Fixed point adder to normalize angle from Q3 back to Q1/Q4 
    fp_adder #(.WI1(WL), .WF1(0), .WI2(WL), .WF2(0), .WIO(), .WFO())
              U1000(.in1(angle), .in2(pi), .out(z_norm_q3), .OVF(OVF));
                  
    always @(posedge CLK) begin
        if(RST) begin
            done <= 0;
            i <= 0;
            cosine <= 0;
            sine <= 0;         
        end
        else if(start) begin
            done <= 0;
            i <= 0;
            if(angle >= pi_2) begin  //If Q2, negate x and subtract current angle by pi
                x <= -K_fp;
                y <= 0;
                z <= z_norm_q2;     //z = angle - pi
            end
            else if(angle <= -pi_2) begin //If Q3, negate x and add pi to current angle
                x <= -K_fp;
                y <= 0;
                z <= z_norm_q3;     //z = angle + pi
            end
            else begin              //If Q1/Q4 keep everything the same
                x <= K_fp;
                y <= 0;
                z <= angle;
            end                          
        end
        else begin
            if(i <= SIZE) begin
                i <= i_next;             //i + 1;
                done <= 0;
                //Synchronize the adders results using next_gt/lt
                if(z >= 0) begin        //Move clockwise to readjust
                    x <= x_next_gt;     //x - (y >>> i);
                    y <= y_next_gt;     //y + (x >>> i);
                    z <= z_next_gt;     //z - atan_table[i];
                end 
                else if(z < 0) begin    //Move counter-clockwise to readjust
                    x <= x_next_lt;     //x + (y >>> i);
                    y <= y_next_lt;     //y - (x >>> i);
                    z <= z_next_lt;     //z + atan_table[i];                
                end
             end
             
             else begin
                done <= 1;
                //0-256 = Q1 // 256-512 = Q2 //(-512)-(-256) = Q3 //(-256)-0 = Q4
                if(angle >= -256 && angle <= 0) begin //Q4
                    cosine <= x >>> 5;
                    sine <= y >>> 5;
                end
                else if(angle >= -512 && angle < -256) begin //Q3
                    cosine <= x >>> 5;
                    sine <= y >>> 5;
                end
                else if(angle >= 256 && angle <= 512) begin //Q2
                    cosine <= x >>> 5;
                    sine <= y >>> 5;
                end
                else begin  //Q1
                    cosine <= x >>> 5;
                    sine <= y >>> 5;
                end           
             end
        end
    end
endmodule


