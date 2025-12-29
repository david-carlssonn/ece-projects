`timescale 1ns / 1ps


module fp_round #(parameter WI = 2, WF = 14, SIGNED = 1)
                (input signed [WI+WF-1:0] in,
                input [1:0] type,
                output reg signed [WI+WF-1:0] out
    );

    wire [WI+WF-1:0] abs_val = (in[WI+WF-1]) ? -in : in;
    wire sign_bit = in[WI+WF-1];
    wire [WF-1:0] frac = abs_val[WF-1:0];
    wire [WI-1:0] int = abs_val[WI+WF-1:WF];
    wire [WF-1:0] point_5 = 1 << (WF-1);
    
    //Pad with 0s to maintain Q(X.X) format
    always @* begin
 //=======================================SIGNED================================================
        if(SIGNED) begin
            //Round down (drop fractional part)
            if(type == 2'b00) out = sign_bit ? -{int, {WF{1'b0}}} : {int, {WF{1'b0}}};
            
            //-------------------Round half up--------------------------------
            else if(type == 2'b01) begin
                //__________________________POS NUM_________________________________________
                if(sign_bit == 0) begin
                    //If frac is 0.5 and up, round toward +inf (int portion + 1), else round opp dir (just int portion)
                    if(frac >= point_5) out = {(int + 1), {WF{1'b0}}};
                    else                out = {int, {WF{1'b0}}};
                end
                
                //_________________________NEG NUM____________________________________________
                else begin
                    //If frac is 0.5 and up, round toward -inf (int portion - 1), else round opp dir (just int portion)
                    if(frac >= point_5) out = -{(int + 1), {WF{1'b0}}};
                    else                out = -{int, {WF{1'b0}}};
                end
            end
            //-----------------------------------------------------------------
            
            //--------------------Round toward nearest even---------------------
            else if(type == 2'b10) begin
                if(frac == point_5) begin
                    //If num is even, throw out frac porition, else add 1 to make even from odd
                    if(int % 2 == 0) out = sign_bit ? -{int, {WF{1'b0}}} : {int, {WF{1'b0}}};
                    else             out = sign_bit ? -{(int + 1), {WF{1'b0}}} : {(int + 1), {WF{1'b0}}};
                end
                //Round up if frac > 0.5
                else if(frac > point_5) out = sign_bit ? -{(int + 1), {WF{1'b0}}} : {(int + 1), {WF{1'b0}}};
                //Round down if frac < 0.5
                else if(frac < point_5) out = sign_bit ? -{int, {WF{1'b0}}} : {int, {WF{1'b0}}};
            end
            //------------------------------------------------------------------
        end
//=============================================================================================

//=========================================UNSIGNED============================================
        else begin
             if(type == 2'b00) out = {int, {WF{1'b0}}};
            //-------------------Round half up--------------------------------
            else if(type == 2'b01) begin
                //If frac is 0.5 and up, round toward +inf (int portion + 1), else round opp dir (just int portion)
                if(frac >= point_5) out = {(int + 1), {WF{1'b0}}};
                else                out = {int, {WF{1'b0}}};
            end
            //------------------------------------------------------------------
            
            //--------------------Round toward nearest even---------------------
            else if(type == 2'b10) begin
                if(frac == point_5) begin
                    //If num is even, throw out frac porition, else add 1 to make even from odd
                    if(int % 2 == 0) out = {int, {WF{1'b0}}};
                    else             out = {(int + 1), {WF{1'b0}}};
                end
                //Round up if frac > 0.5
                else if(frac > point_5) out = {(int + 1), {WF{1'b0}}};
                //Round down if frac < 0.5
                else if(frac < point_5) out = {int, {WF{1'b0}}};
            end
            //------------------------------------------------------------------           
        end
 //==============================================================================================
    end   
endmodule
