`timescale 1ns / 1ps


module FIFO #(parameter WL = 4, N = 4, A_WL = $clog2(N))
             (input CLK, RST, PUSH, POP,
              input [WL-1:0] din,
              output reg EMPTY, FULL,
              output [WL-1:0] head, 
              output reg [WL-1:0] dout
              );
    reg [WL-1:0] in;
    reg [2:0] list_cntr = 0; 
    reg [2:0] list_cntr_next = 0;
    wire [N-1:0] addr_next;
    wire [N-1:0] addr;
    wire push_en = PUSH && !FULL;
    wire pop_en = POP && !EMPTY;
    wire [WL-1:0] head_next;
    //Calculating index for addr
    assign addr = (list_cntr == 0) ? {WL{1'd0}} : list_cntr - 1;

    wire [WL-1:0] head_srl;

    genvar i;
    generate
        for(i = 0; i < 4; i = i + 1) begin
            SRLC16E #(.INIT(16'hxxxx)) U_SRLC16E(
            .D(in[i]),    //Serial data input for 1st bit of din
            .A0(addr[0]),
            .A1(addr[1]),
            .A2(addr[2]),
            .A3(addr[3]),
            .CLK(CLK),
            .CE(push_en),     //Enable shift
            .Q(head_srl[i]),   //Output at address addr
            .Q15()         //N/A
        );            

        end
    endgenerate
 
 
    always @* begin
            list_cntr_next = list_cntr;
            if(push_en) list_cntr_next = list_cntr_next + 1;
            if(pop_en) list_cntr_next = list_cntr_next - 1;
            
            if(list_cntr == N) FULL = 1;
            else FULL = 0;
            if(list_cntr == 0) EMPTY = 1;
            else EMPTY = 0;
    end
    
    //When emptying list, make head null
    assign head = (EMPTY) ? {WL{1'bx}} : head_srl;
    
    always @(posedge CLK) begin
        //Technically addr is sync even though its calculated combinationally because of list_cntr so that means you must register input as well so everything is in sync
        in <= din;
        list_cntr <= list_cntr_next;
        if(RST) begin
            EMPTY <= 1;
            FULL <= 0;
            dout <= 1'bx;
        end
        else begin
            if(POP && !EMPTY) dout <= head;
            else if(EMPTY) dout <= 1'bx;
        end
    end
endmodule
