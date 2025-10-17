`timescale 1ns / 1ps

module tb_fixedp_addr_mult;

    parameter tb_WI1 = 5, tb_WF1 = 4, tb_WI2 = 7, tb_WF2 = 3, 
              tba_WIO = ((tb_WI1 > tb_WI2) ? tb_WI1 : tb_WI2), tba_WFO = ((tb_WF1 > tb_WF2) ? tb_WF1 : tb_WF2),
              tbm_WIO = tb_WI1+tb_WI2, tbm_WFO = tb_WF1+tb_WF2;
    reg CLK;
    reg signed [tb_WI1+tb_WF1-1:0] in1;
    reg signed [tb_WI2+tb_WF2-1:0] in2;
    wire signed [tba_WIO+tba_WFO-1:0] out_a;
    wire signed [tbm_WIO+tbm_WFO-1:0] out_m;
    wire OVF;
    
    initial CLK = 0;
    always #5 CLK = ~CLK;
    
    fixedp_addr #(.WI1(tb_WI1), .WF1(tb_WF1), .WI2(tb_WI2), .WF2(tb_WF2), .WIO(), .WFO())
              U00(.in1(in1), .in2(in2), .out(out_a), .OVF(OVF));
    fixedp_mult #(.WI1(tb_WI1), .WF1(tb_WF1), .WI2(tb_WI2), .WF2(tb_WF2), .WIO(tbm_WIO), .WFO(tbm_WFO))
              U01(.in1(in1), .in2(in2), .out(out_m));
    initial begin
        in1=0; in2=0;
        @(posedge CLK);         //Largest +in1 largest +in2
        in1 = 9'b011111111;
        in2 = 10'b0111111111;
        @(posedge CLK);         //Largest -in1 largest -in2
        in1 = 9'b111111111;
        in2 = 10'b1111111111;
        @(posedge CLK);         //Largest +in1 largest -in2
        in1 = 9'b011111111;
        in2 = 10'b1111111111;
        @(posedge CLK);         //Smallest +in1 largest +in2
        in1 = 9'b000000001;
        in2 = 10'b0111111111;
        @(posedge CLK);         //Smallest -in1 largest -in2
        in1 = 9'b100000000;
        in2 = 10'b1111111111;
        @(posedge CLK);         //Smallest +in1 largest -in2
        in1 = 9'b000000001;
        in2 = 10'b1111111111;

        @(posedge CLK);         //Largest +in1 smallest +in2
        in1 = 9'b011111111;
        in2 = 10'b0000000001;
        @(posedge CLK);         //Largest -in1 smallest -in2
        in1 = 9'b111111111;
        in2 = 10'b1000000000;
        @(posedge CLK);         //Largest +in1 smallest -in2
        in1 = 9'b011111111;
        in2 = 10'b1000000000;
        @(posedge CLK);         //Smallest +in1 smallest +in2
        in1 = 9'b000000001;
        in2 = 10'b0000000001;
        @(posedge CLK);         //Smallest -in1 smallest -in2
        in1 = 9'b100000000;
        in2 = 10'b1000000000;
        @(posedge CLK);         //Smallest +in1 smallest -in2
        in1 = 9'b000000001;
        in2 = 10'b1000000000;                                       
        repeat(3) @(posedge CLK);

        $finish;
    end
endmodule
