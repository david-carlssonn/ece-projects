`timescale 1ns / 1ps

module tb_pla_cos;
    parameter tb_WI1 = 4, tb_WF1 = 12, tb_WI2 = 2, tb_WF2 = 14, tb_Widx = 6;
    reg CLK;
    reg signed [tb_WI1+tb_WF1-1:0] x;
    wire signed [tb_WI2+tb_WF2-1:0] y;
    real y_real;
    integer cyc_count, out, print_count, valid_print;
  
    initial CLK = 0;
    always #5 CLK = ~CLK;
    
    pla_cos U00(.CLK(CLK), .x(x), .y(y));
    
    initial out = $fopen("pla_verilog_output.txt", "w");
    
    initial begin
        $monitor("Time:%0t|x:%0b|x_pipe:%0b|x_pipe2:%0b|y:%0d|index:%0d|b:%0b|coeffs:%0b|mult_ax:%0b|seg_size:%0b", 
                 $time, x, U00.x_pipe, U00.x_pipe2, y, U00.index, U00.b, U00.coeffs, U00.mult_ax, U00.seg_size);
        x = 0;
        cyc_count = 0;
        print_count = 0;
        valid_print = 0;
        repeat(4) @(posedge CLK);
    end
    always@(posedge CLK) begin
        cyc_count = cyc_count + 1;  //Sends in a new input every 4 posedges
        if(cyc_count == 4) begin
            cyc_count = 0;
            if(valid_print) begin   //Only prints after first valid output is generated
                y_real = $itor(y) / (2**14);
                if(print_count < 255) $fwrite(out, "%b\n", y);
                print_count = print_count + 1;
                x = x + 16'd100;    //Increment by 100 --> 2pi/256 = 0.0245 * 2^12 = 100 Q(4.12)
            end
            else valid_print = 1;
        end
        
        //For last value print y with no newline and close file
        if(print_count == 255) begin
            $fwrite(out, "%b", y);
            $fclose(out);
            $finish;
        end
    end
endmodule
