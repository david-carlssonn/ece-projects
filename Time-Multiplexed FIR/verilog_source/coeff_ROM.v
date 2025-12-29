`timescale 1ns / 1ps

module coeff_ROM #(parameter N = 64, M = 16, WIC = 1, WFC = 15)
                  (output signed [N*(WIC+WFC)-1:0] coeffs_full
    );
    
    reg signed [WIC+WFC-1:0] coeffs [0:N-1];
    initial $readmemh("HW6_BPF_hex.txt", coeffs);
    
    
    genvar i;
    generate
        //Compress coefficients into a long bus for later extraction
        //i = 0 -> coeffs_full[WIC+WFC-1:0] = coeffs[0]---------------> coeffs_full[15:0] = coeffs[0]
        //i = 1 -> coeffs_full[2*(WIC+WFC)-1:WIC+WFC] = coeffs[1]-----> coeffs_full[31:16] = coeffs[1]
        //i = 2 -> coeffs_full[3*(WIC+WFC)-1:2*(WIC+WFC)] = coeffs[2]-> coeffs_full[47:32] = coeffs[2]
        //Continues until all coefficients are in a single bus
        for(i = 0; i < N; i = i + 1) begin
            assign coeffs_full[(i+1)*(WIC+WFC)-1:i*(WIC+WFC)] = coeffs[i];
        end
    endgenerate
    
endmodule
