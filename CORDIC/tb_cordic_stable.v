`timescale 1ns / 1ps


module tb_cordic_stable;

    parameter WL = 10, WIO = 1, WFO = 9;
    reg CLK, RST, start;
    reg signed [WL-1:0] angle;
    wire signed [WL-1:0] angle_next;
    wire signed [WIO+WFO-1:0] cosine, sine;
    wire done;
    wire OVF;
    
    real angle_real;
    
    integer file;
    integer count = 0;
    
    //Gets txt file ready for writing
    initial file = $fopen("cordic_verilog_output.txt", "w");
    
    initial CLK = 0;
    always #5 CLK = ~CLK;
    
    cordic_stable U00 (.CLK(CLK), .RST(RST), .start(start), .angle(angle), .cosine(cosine), .sine(sine), .done(done));
    
    //Fixed point adder to increment angle by 10 degree increments (10 degrees --> 0.174533 rad * (512/pi) = 28)
    fp_adder #(.WI1(WL), .WF1(0), .WI2(WL), .WF2(0), .WIO(), .WFO())
              U1111(.in1(angle), .in2(10'd28), .out(angle_next), .OVF(OVF));
    
    initial begin
        angle = 10'd0;
        start = 0;
        RST = 1;
        @(posedge CLK);
        RST = 0;
    end

    //Calculation for true angle in radians to scale down from 512
    always @* begin
        angle_real = angle * 3.1415926535 / 512.0;
    end
                  
    //Sampling on negedge to counteract race condition
    always @(negedge CLK) begin
        $monitor("Time: %0t | RST = %b | angle = %0d | X = %b | Y = %b | Z = %b | i = %d | sine = %0d | cosine = %0d ", 
                  $time, RST, angle, U00.x, U00.y, U00.z, U00.i, sine, cosine);
        if(done) begin
            angle <= angle_next;
            $fwrite(file, "%0d,%0d,%0d\n", (count*10), cosine, sine);
            count <= count + 1;
            start <= 1;
        end
        else start <= 0;
        //After 360 degrees close the file
        if(count > 36) $fclose(file);
    end
endmodule
