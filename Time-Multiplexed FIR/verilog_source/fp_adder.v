`timescale 1ns / 1ps


module fp_adder #(parameter WI1 = 4, WF1 = 16, WI2 = 4, WF2 = 16, 
                     WIO = ((WI1 > WI2) ? WI1 : WI2) + 1, 
                     WFO = ((WF1 > WF2) ? WF1 : WF2))
                    (input signed[WI1+WF1-1:0] in1,
                     input signed[WI2+WF2-1:0] in2,
                     output reg signed [WIO+WFO-1:0] out,
                     output reg OVF
                    );
    
    localparam i_max = (WI1 > WI2) ? WI1 : WI2;
    localparam f_max = (WF1 > WF2) ? WF1 : WF2;
    
    reg signed [i_max+f_max:0] in1_ext;
    reg signed [i_max+f_max:0] in2_ext;

    always @* begin

        //If in1 has more fractional and integer bits, sign extend and pad in2
        if(WI1 > WI2 && WF1 > WF2) begin
            in1_ext = in1;
            in2_ext = {{(WI1-WI2){in2[WI2+WF2-1]}}, in2, {(WF1-WF2){1'b0}}};
        end
        //If in2 has more fractional and integer bits, sign extend and pad in1
        else if(WI1 < WI2 && WF1 < WF2) begin
            in1_ext = {{(WI2-WI1){in1[WI1+WF1-1]}}, in1, {(WF2-WF1){1'b0}}};
            in2_ext = in2;
        end
        //If in1 has more integer bits but in2 has more fractional bits, sign extend in2 and pad in1
         else if(WI1 > WI2 && WF1 < WF2) begin
            in1_ext = {in1, {(WF2-WF1){1'b0}}};
            in2_ext = {{(WI1-WI2){in2[WI2+WF2-1]}}, in2};
        end
        //If in2 has more integer bits but in1 has more fractional bits, sign extend in1 and pad in2
         else if(WI1 < WI2 && WF1 > WF2) begin
            in1_ext = {{(WI2-WI1){in1[WI1+WF1-1]}}, in1};
            in2_ext = {in2, {(WF1-WF2){1'b0}}};
        end
        //If in1 has more integer bits, sign extend in2
        else if(WI1 > WI2 && WF1 == WF2) begin
            in1_ext = in1;
            in2_ext = {{(WI1-WI2){in2[WI2+WF2-1]}}, in2};
        end
        //If in2 has more integer bits, sign extend in1
        else if(WI1 < WI2 && WF1 == WF2) begin
            in1_ext = {{(WI2-WI1){in1[WI1+WF1-1]}}, in1};
            in2_ext = in2;
        end
        //If in1 has more fractional bits, pad in2       
        else if(WF1 > WF2 && WI1 == WI2) begin
            in1_ext = in1;
            in2_ext = {in2, {(WF1-WF2){1'b0}}};
        end
        //If in2 has more fractional bits, pad in1 
        else if(WF1 < WF2 && WI1 == WI2) begin
            in1_ext = {in1, {(WF2-WF1){1'b0}}};
            in2_ext = in2;
        end
        //Already alinged
        else if(WI1 == WI2 && WF1 == WF2) begin
            in1_ext = in1;
            in2_ext = in2;
        end
        
        out = in1_ext + in2_ext;
        
        //Checks to see if input sign bit matches output sign bit
        OVF = ((in1_ext[i_max+f_max-1]) == (in2_ext[i_max+f_max-1])) 
            && (out[i_max+f_max-1] != (in1_ext[i_max+f_max-1]));   
            
    end               
endmodule