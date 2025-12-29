`timescale 1ns / 1ps


module tb_fp_round;
    
    parameter WI = 2, WF = 14;
    reg CLK;
    reg signed [WI+WF-1:0] in;
    reg [1:0] type;
    wire signed [WI+WF-1:0] y_z, y_u, y_e;
    initial CLK = 0;
    always #5 CLK = ~CLK;
    integer i, f_down, f_halfup, f_even;
    real real_down, real_halfup, real_even;
    
    fp_round #(.WI(WI), .WF(WF)) down (.in(in), .type(00), .out(y_z));
    fp_round #(.WI(WI), .WF(WF)) halfup (.in(in), .type(01), .out(y_u));
    fp_round #(.WI(WI), .WF(WF)) even (.in(in), .type(10), .out(y_e));

    reg signed [2*WI+2*WF-1:0] pla_values [255:0];
    initial $readmemb("pla_verilog_output.txt", pla_values);
    
    initial begin
    
    f_down = $fopen("round_down.txt", "w");
    f_halfup = $fopen("round_halfup.txt", "w");
    f_even = $fopen("round_even.txt", "w");
    
    for (i = 0; i < 256; i = i + 1) begin
        in = pla_values[i];
        #5;
        //Calculate real values for each rounded value
        real_down = $itor(y_z) / (2**WF);
        real_halfup = $itor(y_u) / (2**WF);
        real_even = $itor(y_e) / (2**WF);
        
        //Store them in their respective txt files
        $fwrite(f_down, "%f\n", real_down);
        $fwrite(f_halfup, "%f\n", real_halfup);
        $fwrite(f_even, "%f\n", real_even);
    end

    $fclose(f_down);
    $fclose(f_halfup);
    $fclose(f_even);
    $finish;
    end
endmodule
