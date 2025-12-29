`timescale 1ns / 1ps


module tb_sos_cascade;
    parameter WI = 2, WF = 10;
    integer i, rst_count;
    reg CLK;
    reg rst;
    reg signed [WI+WF-1:0] signal;
    wire signed [WI+WF-1:0] filtered;
    reg signed [WI+WF-1:0] Neural_Signal [0:3999];
    
    initial $readmemb("Neural_Signal_Sample.txt", Neural_Signal);
    
    initial CLK = 0;
    always #5 CLK = ~CLK;
    
    sos_cascade #(.WIC(), .WFC(), .WI_IN(), .WF_IN(), .WI_OUT(), .WF_OUT(), .G_NUM(5), .SOS_NUM(4)) U00 (.CLK(CLK), .rst(rst), .signal(signal), .filtered(filtered));    
    initial i = 0;

//Random Inputs
initial begin

    rst = 1; 
    repeat(2) @(posedge CLK);
//    x = 0;
//    #20;
    rst = 0;
//    #10;
//    x = 12'b001100000000; @(posedge CLK);  // +0.75
//    x = 12'b101100000000; @(posedge CLK);  // -1.25
//    x = 12'b001000000000; @(posedge CLK);  // +0.5
//    x = 12'b111010000000; @(posedge CLK);  // -0.375
//    x = 0; @(posedge CLK)
//    #500;
    
//    $finish;
//end
        signal <= 12'd102;   //0.1 in Q2.10
        @(posedge CLK);
        signal <= 12'd154;   //0.15 in Q2.10
        @(posedge CLK);
        signal <= 12'd205;  //0.2 in Q2.10
        @(posedge CLK);
        signal <= 12'd307;   //0.3 in Q2.10
        @(posedge CLK);
        signal <= 12'd768;   //0.75 in Q2.10
        @(posedge CLK);
        signal <= 12'd461;   //0.45 in Q2.10
        @(posedge CLK);
        signal <= 12'd3840;  //-0.25 in Q2.10
        @(posedge CLK);
        signal <= 12'd1024;  //1.0 in Q2.10
        @(posedge CLK);
        signal <= 12'd819;  //0.8 in Q2.10
        @(posedge CLK);
        signal <= 12'd3072;   //-1.0 in Q2.10
        @(posedge CLK);
        signal <= 12'd676;   //0.66 in Q2.10        
        @(posedge CLK); 
        signal <= 12'd338;   //0.33 in Q2.10
        @(posedge CLK);
        signal <= 12'd102;   //0.1 in Q2.10
        @(posedge CLK);
        signal <= 12'd2867;  //-1.2 in Q2.10
        repeat(200) @(posedge CLK);
        $finish;
        end
//    integer out;
    
//    initial out = $fopen("sos_cascade_out.txt", "w");
    
//    initial rst_count = 0;
//    initial i = 0;
//    always @(posedge CLK) begin
//        if(rst_count < 2) begin
//            rst_count <= rst_count + 1;
//            rst = 1;
//        end
//        else if(i <= 4000 && rst_count == 2) begin
//            rst = 0;
//            signal <= Neural_Signal[i];
//            i = i + 1;
//            //Only write to file when output is valid
//            if(i > 30) begin
//                $fwrite(out, "%0d\n", filtered);
//            end
//        end
//        if(i > 4000) begin
//            $fclose(out);
//            $finish;
//        end
//    end

endmodule   