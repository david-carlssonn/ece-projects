`timescale 1ns / 1ps


module tb_FIFO;
    localparam WL_tb = 4, N_tb = 4, A_WL_tb = $clog2(N_tb);
    reg CLK, RST, PUSH, POP;
    reg [WL_tb-1:0] din;
    wire EMPTY, FULL;
    wire [WL_tb-1:0] head;
    wire [WL_tb-1:0] dout;
    
    initial CLK = 0;
    always #5 CLK = ~CLK;

    FIFO #(.WL(WL_tb), .N(N_tb), .A_WL(A_WL_tb)) 
       U00(.CLK(CLK), .RST(RST), .PUSH(PUSH), .POP(POP), .din(din), 
           .EMPTY(EMPTY), .FULL(FULL), .head(head), .dout(dout));
       
    initial begin
    
    $monitor("time=%0t addr=%0d list_cntr=%0d list_cntr_next=%0d EMPTY=%0d FULL=0%d PUSH=%0d POP=%0d head=%0d din=%0d", 
             $time, U00.addr, U00.list_cntr, U00.list_cntr_next, EMPTY, FULL, PUSH, POP, U00.head, din);

        RST = 1; PUSH = 0; POP = 0;
        
        //Repeated to stabilize values
        
        repeat(2) @(posedge CLK); //PUSH 3
        RST = 0; 
        din = 3; PUSH = 1; POP = 0;  
              
        @(posedge CLK); //PUSH 4
        din = 4; PUSH = 1; POP = 0;
        
        @(posedge CLK); //POP
        POP = 1;  PUSH = 0; 
        
        @(posedge CLK); POP = 0;
        
        @(posedge CLK); //PUSH 7
        din = 7; PUSH = 1; POP = 0;
        
        @(posedge CLK); //PUSH 6
        din = 6; PUSH = 1; POP = 0;
        
        @(posedge CLK); //PUSH 2
        din = 2; PUSH = 1; POP = 0;
        
        @(posedge CLK); //PUSH 1
        din = 1; PUSH = 1; POP = 0;
        
        @(posedge CLK); //POP
        PUSH = 0; POP = 1;

        @(posedge CLK); //POP
        PUSH = 0; POP = 1;
        
        @(posedge CLK); //POP
        PUSH = 0; POP = 1;
        
        @(posedge CLK); //POP
        PUSH = 0; POP = 1;
        
        @(posedge CLK); //POP
        PUSH = 0; POP = 1;
        
        repeat(5) @(posedge CLK);
 

       $finish;
    end 
endmodule
