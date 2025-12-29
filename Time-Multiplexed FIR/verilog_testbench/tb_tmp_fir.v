`timescale 1ns / 1ps


module tb_tmp_fir;

    parameter WII = 2, WFI = 10, N = 64, M = 16;
    integer i, out, out_srl;
    reg signed [WII+WFI-1:0] x;
    reg RST;
    reg in_valid;
    reg CLK;
    wire signed [WII+WFI-1:0] y, y_srl;
    wire out_valid;
    reg signed [WII+WFI-1:0] Neural_Signal [0:3999];
    
    initial $readmemb("Neural_Signal_Sample.txt", Neural_Signal);
    initial CLK = 0;
    always #5 CLK = ~CLK;
    
    //FIR using registers for delay line
    tmp_fir #(.SRL_REG(0)) U00(.x(x), .CLK(CLK), .RST(RST), .in_valid(in_valid), .y(y), .out_valid(out_valid));
    
    //FIR using SRL16s for delay line
    tmp_fir #(.SRL_REG(1)) U01(.x(x), .CLK(CLK), .RST(RST), .in_valid(in_valid), .y(y_srl), .out_valid(out_valid));
    
    initial i = 0;
    initial out = $fopen("tmp_fir_out.txt", "w");
    initial out_srl = $fopen("tmp_fir_srl_out.txt", "w");
        
    initial begin
        RST = 1;
        in_valid = 0;
        
        repeat(2) @(posedge CLK);
        RST = 0;

        for(i = 0; i < 4000; i = i + 1) begin
            x = Neural_Signal[i];
            in_valid = 1'b1;
            @(posedge CLK);         //IDLE --> ACCUM
            in_valid = 1'b0;
            @(posedge out_valid);   //ACCUM --> DONE (Wait for out_valid)
            @(posedge CLK);         //DONE --> IDLE (Repeat)
            //Wait until first valid output to write to txt file
            if(i > N-2) begin                
                $fdisplay(out, "%0d", y);
                $fdisplay(out_srl, "%0d", y_srl);
            end
        end
        repeat(10) @(posedge CLK);
        $fclose(out);
        $fclose(out_srl);
        $finish;    
    end
//Random Inputs        
//        x = 12'd154;   //0.15 in Q2.10
//        in_valid = 1'b1;
//        @(posedge CLK);
//        in_valid = 1'b0;
//        @(posedge out_valid);
//        @(posedge CLK);
        
        
//        x = 12'd205;  //0.2 in Q2.10
//        in_valid = 1'b1;
//        @(posedge CLK);
//        in_valid = 1'b0;
//        @(posedge out_valid);
//        @(posedge CLK);

//        x = 12'd307;   //0.3 in Q2.10
//        in_valid = 1'b1;
//        @(posedge CLK);
//        in_valid = 1'b0;
//        @(posedge out_valid);
//        @(posedge CLK);
        
//        x = 12'd768;   //0.75 in Q2.10
//        in_valid = 1'b1;
//        @(posedge CLK);
//        in_valid = 1'b0;
//        @(posedge out_valid);
//        @(posedge CLK);
        
//        x = 12'd461;   //0.45 in Q2.10
//        in_valid = 1'b1;
//        @(posedge CLK);
//        in_valid = 1'b0;
//        @(posedge out_valid);
//        @(posedge CLK);
        
//        x = 12'd3840;  //-0.25 in Q2.10
//        in_valid = 1'b1;
//        @(posedge CLK);
//        in_valid = 1'b0;
//        @(posedge out_valid);
//        @(posedge CLK);
//        repeat(10) @(posedge CLK);
//        $finish;                   
//    end

endmodule
