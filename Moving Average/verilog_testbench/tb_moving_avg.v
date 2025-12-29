`timescale 1ns / 1ps


module tb_moving_avg;

    //Setting window size/bit width for main module through instanstiation
    localparam L_tb = 8, L_mem = 4096, WL_tb = 16;
    
    reg CLK, RST, valid;
    reg [WL_tb-1:0] din;
    wire [WL_tb-1:0] avg;
    integer frame, out_file, write_cnt;
    
    reg [WL_tb-1:0] tb_window [L_mem-1:0];
    
    initial CLK = 0;
    always #5 CLK = ~CLK;
    
    moving_avg #(.L(L_tb), .WL(WL_tb)) U00 
                (.CLK(CLK), .RST(RST), .valid(valid), .din(din), .avg(avg));
    
    initial $readmemb("HW0_Input_tb.mem", tb_window);  //Loading data from input file into tb_window
    
    initial begin
    
    //Monitor all significant signals for debugging
    $monitor("time:%0t, window[0]:%0d, window[1]:%0d, window[2]:%0d, window[3]:%0d state:%0d count:%0d sum:%0d avg:%0d", 
             $time, U00.window[0], U00.window[1], U00.window[2], U00.window[3], U00.state, U00.count, U00.sum, U00.avg);
    
    RST = 1; din = 0; write_cnt = 0;
    repeat(2) @(posedge CLK);                       //2 cycle RST to ensure clean start
    RST = 0; valid = 1;

    for(frame=0; frame<L_mem; frame=frame+1) begin  //Shifting in values from input file into din
        din = tb_window[frame];
        repeat(3) @(posedge CLK);
    end

      //Example test with values shown in the hw prompt (commented out for now)
//    din = 4'b0010;
//    repeat(3) @(posedge CLK);
//    din = 4'b0011;
//    repeat(3) @(posedge CLK);
//    din = 4'b0100;
//    repeat(3) @(posedge CLK);
//    din = 4'b0101;
//    repeat(3) @(posedge CLK);
//    din = 4'b0110;
//    repeat(3) @(posedge CLK);
//    din = 4'b1000;
//    repeat(12) @(posedge CLK);
//    @(posedge CLK);
    $finish;
    end
    
    initial begin
        //Gets txt file ready for writing
        out_file = $fopen("avg_output L=8.txt", "w");
        //$Finish if file couldn't be opened
        if(out_file == 0) $finish;
     end
     
     always @(posedge CLK) begin
        if(valid) begin
            //Write output into blank txt
            $fdisplay(out_file, "Time: %0t | Din(Binary): %b | Average(Binary): %b | Din(Decimal): %0d | Average(Decimal): %0d",
                      $time, din, avg, din, avg);
            write_cnt = write_cnt + 1;
        end
        //After all outputs have been written, close the file
        //4096*3 since there are 3 cycles in between each output so 12288 lines in total
        if(write_cnt == L_mem*3) begin
            $fclose(out_file);
        end
     end
endmodule
