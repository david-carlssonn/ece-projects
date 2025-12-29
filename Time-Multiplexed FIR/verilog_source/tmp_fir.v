`timescale 1ns / 1ps


module tmp_fir #(parameter N = 64, M = 16, CW = $clog2(CYCLE_NUM), CYCLE_NUM = N/M, SRL_REG = 0,
                parameter WII = 2, WFI = 10, WIO = WII, WFO = WFI, INT_WI = 2, INT_WF = 30, WI_COEFF = 1, WF_COEFF = 15)
               (input signed [WII+WFI-1:0] x,
                input CLK, RST, in_valid,
                output reg signed [WIO+WFO-1:0] y,
                output reg out_valid
                );
    localparam IDLE = 2'b00, ACCUM = 2'b01, DONE = 2'b10;
    reg [1:0] state;
    reg [3:0] addr = 4'b0000;
    reg shift_en;
    reg SRL_CE;   
    reg [CW:0] cyc;            
    wire signed [WII+WFI-1:0] x_d [0:N-2];
    reg signed [INT_WI+INT_WF-1:0] accum;
    wire signed [WI_COEFF+WF_COEFF-1:0] coeff [0:N-1];
    wire signed [N*(WI_COEFF+WF_COEFF)-1:0] coeffs_full;
    wire signed [INT_WI+INT_WF-1:0] add [0:M-1];
    wire signed [INT_WI+INT_WF-1:0] mult [0:M-1];
               
    genvar i, j, z;
    //-----------------------COEFF EXTRACTION-----------------------------
    
    coeff_ROM #(.N(N)) U111111 (.coeffs_full(coeffs_full));
    
    //z = 0 -> coeffs_full[WI_COEFF+WF_COEFF-1:0]-------------------------> coeff[0] = coeffs_full[15:0]
    //z = 1 -> coeffs_full[2*(WI_COEFF+WF_COEFF)-1:WI_COEFF+WF_COEFF]-----> coeff[1] = coeffs_full[31:16]
    //z = 2 -> coeffs_full[3*(WI_COEFF+WF_COEFF)-1:2*(WI_COEFF+WF_COEFF)]-> coeff[2] = coeffs_full[47:32]
    //Continues until all N coefficients are filled into coeff
    generate
        for(z = 0; z < N; z = z + 1) begin
            assign coeff[z] = coeffs_full[(z+1)*(WI_COEFF+WF_COEFF)-1:z*(WI_COEFF+WF_COEFF)];
        end
    endgenerate
    //--------------------------------------------------------------------
    //---------------------REGISTER GENERATION----------------------------
    generate
    
        /////////////If SRL_REG is 0 use a standard delay line///////////
        if(SRL_REG == 0) begin
            for(i = 0; i < N-1; i = i + 1) begin
                //If first register, take x as input
                if(i == 0) register U000 (.CLK(CLK), .din(shift_en ? x : x_d[i]), .q(x_d[i]));
                //After first register, take previous register output as input
                else register U001 (.CLK(CLK), .din(shift_en ? x_d[i-1] : x_d[i]), .q(x_d[i]));
            end
        end
        /////////////////////////////////////////////////////////////////
        //////////////If SRL_REG is 1 use SRL16s for delay line//////////
        else begin
            for(i = 0; i < N-1; i = i + 1) begin
                for(j = 0; j < WII+WFI; j = j + 1) begin
                //Generate SRL16s for j bits to match input bit width
                    if(i == 0)
                    SRLC16E #(.INIT(16'hxxxx)) U_SRLC16E(
                    .D(x[j]),       //If first srl16 being made, input is x
                    .A0(addr[0]),
                    .A1(addr[1]),
                    .A2(addr[2]),
                    .A3(addr[3]),
                    .CLK(CLK),
                    .CE(SRL_CE),     //Enable shift after accum
                    .Q(x_d[i][j]),   //Output after first reg (addr = 0)
                    .Q15()           //N/A
                );
                    else
                    SRLC16E #(.INIT(16'hxxxx)) U_SRLC16E(
                    .D(x_d[i-1][j]), //After first srl16 is made, input is delayed x
                    .A0(addr[0]),
                    .A1(addr[1]),
                    .A2(addr[2]),
                    .A3(addr[3]),
                    .CLK(CLK),
                    .CE(SRL_CE),     //Enable shift after accum
                    .Q(x_d[i][j]),   //Output after first reg (addr = 0)
                    .Q15()           //N/A
                );
                end
            end        
        end
        /////////////////////////////////////////////////////////////////
    endgenerate
    //--------------------------------------------------------------------
    //----------------------MULTIPLIER GENERATION-------------------------
    //For each cycle, a different block of coeffs is selected dependent on the cycle and i (independent from i if first mult)
    //Coeffs for cyc 0 --> coeff[0 . . . M-1]
    //Coeffs for cyc 1 --> coeff[M <-(for first multiplier) . . . 2M-1]
    //Coeffs for cyc 2 --> coeff[2M <-(first mult again) . . . 3M-1]
    //Continues on until CYCLE_NUM....
    generate
        for(i = 0; i < M; i = i + 1) begin
            //If first multiplier, use mux that is independent from i to determine coeffs and x/register input
            if(i == 0) fp_mult #(.WI1(WI_COEFF), .WF1(WF_COEFF), .WI2(WII), .WF2(WFI), .WIO(INT_WI), .WFO(INT_WF)) 
                      U010(.in1(coeff[(cyc == 0) ? i : M*cyc]), .in2(cyc == 0 ? x : x_d[(M*cyc)-1]), .out(mult[i]));
            //For the following multipliers, use mux that is dependent on i to determine coeffs and register input
            else fp_mult #(.WI1(WI_COEFF), .WF1(WF_COEFF), .WI2(WII), .WF2(WFI), .WIO(INT_WI), .WFO(INT_WF)) 
                      U011(.in1(coeff[(cyc == 0) ? i : (M*cyc)+i]), .in2(cyc == 0 ? x_d[i-1] : x_d[((M*cyc)-1)+i]), .out(mult[i]));
        end
    endgenerate
    //For each cycle, a different delay element value is selected dependent on the cycle and i (independent from i if first mult)
    //Inputs for cyc 0 --> = x, x_d[0], x_d[1], x_d[2]...                (newest inputs)
    //Inputs for cyc 1 --> = x_d[M-1], x_d[M], x_d[M+1], x_d[M+2]...
    //Inputs for cyc 2 --> = x_d[2M-1], x_d[2M], x_d[2M+1], x_d[2M+2]... (oldest inputs)
    //Continues on until CYCLE_NUM....
    //--------------------------------------------------------------------
    //------------------------ADDER GENERATION----------------------------
    generate
        for(i = 0; i < M; i = i + 1) begin
            //If first adder, take only first multiplier as input
            if(i == 0) fp_adder #(.WI1(INT_WI), .WF1(INT_WF), .WI2(INT_WI), .WF2(INT_WF), .WIO(INT_WI), .WFO(INT_WF)) 
                       U100(.in1(mult[i]), .in2(0), .out(add[i]), .OVF());
            //After first adder, take output of multiplier lined up with adder and previous addition as inputs
            else fp_adder #(.WI1(INT_WI), .WF1(INT_WF), .WI2(INT_WI), .WF2(INT_WF), .WIO(INT_WI), .WFO(INT_WF)) 
                       U101(.in1(mult[i]), .in2(add[i-1]), .out(add[i]), .OVF());
        end
    endgenerate
    //--------------------------------------------------------------------
    
    always @(posedge CLK) begin
        if(RST) begin
            state <= IDLE;
            cyc <= 0;
            out_valid <= 0;
            accum <= 0;
            shift_en <= 0;
            SRL_CE <= 0;
            y <= 0;
        end
        else begin
            case(state)
                IDLE: begin
                    cyc <= 0;
                    out_valid <= 0;
                    shift_en <= 0;
                    SRL_CE <= 0;
                    //Only move to ACCUM if there is valid data
                    if(in_valid) begin
                        state <= ACCUM;
                        accum <= 0;
                    end
                end
                ACCUM: begin
                    shift_en <= 0;
                    SRL_CE <= 0;
                    accum <= accum + add[M-1];
                    //Continue accumulating until N/M cycles have passed
                    if(cyc < CYCLE_NUM-1) begin
                        cyc <= cyc + 1;
                    end
                    //Shifting the SRL16 a cycle early to be synced with FFs
                    else begin
                        cyc <= 0;
                        SRL_CE <= 1;
                        state <= DONE;
                    end
                end
                DONE: begin
                    //Multipliers convert WL to Q2.30 so shift by 20 to convert to Q2.10
                    y <= accum >>> (INT_WF - WFO);
                    shift_en <= 1;
                    SRL_CE <= 0;
                    out_valid <= 1;
                    state <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule
