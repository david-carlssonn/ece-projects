`timescale 1ns / 1ps


module tb_sos;
    parameter WI = 2, WF = 10;
    integer i, rst_count;
    reg signed [WI+WF-1:0] x;
    reg CLK;
    reg rst;
    wire signed [WI+WF-1:0] y;
    reg signed [WI+WF-1:0] Neural_Signal [0:3999];
    
    initial $readmemb("Neural_Signal_Sample.txt", Neural_Signal);
    
    initial CLK = 0;
    always #5 CLK = ~CLK;
    
    sos #(.SOS_NUM(0))U00(.CLK(CLK), .rst(rst), .x(x), .y(y));    
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
        x <= 12'd102;   //0.1 in Q2.10
        @(posedge CLK);
        x <= 12'd154;   //0.15 in Q2.10
        @(posedge CLK);
        x <= 12'd205;  //0.2 in Q2.10
        @(posedge CLK);
        x <= 12'd307;   //0.3 in Q2.10
        @(posedge CLK);
        x <= 12'd768;   //0.75 in Q2.10
        @(posedge CLK);
        x <= 12'd461;   //0.45 in Q2.10
        @(posedge CLK);
        x <= 12'd3840;  //-0.25 in Q2.10
        @(posedge CLK);
        x <= 12'd1024;  //1.0 in Q2.10
        @(posedge CLK);
        x <= 12'd819;  //0.8 in Q2.10
        @(posedge CLK);
        x <= 12'd3072;   //-1.0 in Q2.10
        @(posedge CLK);
        x <= 12'd676;   //0.66 in Q2.10        
        @(posedge CLK); 
        x <= 12'd338;   //0.33 in Q2.10
        @(posedge CLK);
        x <= 12'd102;   //0.1 in Q2.10
        @(posedge CLK);
        x <= 12'd2867;  //-1.2 in Q2.10
        repeat(10) @(posedge CLK);
        $finish;
        end
//    initial rst_count = 0;
//    initial i = 0;
//    always @(posedge CLK) begin
//        if(rst_count < 1) begin
//            rst_count <= rst_count + 1;
//            rst = 1;
//        end
//        else if(i <= 4000 && rst_count == 1) begin
//            rst = 0;
//            x <= Neural_Signal[i];
//            i = i + 1;
////            //Only write to file when output is valid
////            if(i > 7) begin
////                $fdisplay(out, "%0d", y);
////                $fdisplay(out_srl, "%0d", y_srl);
////            end
////        end
//        if(i > 4000)
////            $fclose(out);
////            $fclose(out_srl);
//            $finish;
//        end
//    end

endmodule   