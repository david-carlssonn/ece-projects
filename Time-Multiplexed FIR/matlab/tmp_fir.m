WII = 2;
WFI = 10;
fp = 2^WFI;
W = WII+WFI;
WIC = 1;
WFC = 15;
WC  = WIC+WFC;


fid = fopen('Neural_Signal_Sample.txt', 'r');
binInput = textscan(fid, '%s');
fclose(fid);
stringInputs = binInput{1};

%Convert binary strings to signed integers
x_int = zeros(length(stringInputs), 1);
for i = 1:length(stringInputs)
    %Take each binary input and convert to decimal
    unsigned_val = bin2dec(stringInputs{i});
    if unsigned_val >= 2^(W - 1)        %If the sign bit is 1..
        x_int(i) = unsigned_val - 2^W;  %If negative, subtract by MSB value
    else
        x_int(i) = unsigned_val;        %If positive, keep the same
    end
end

%Convert to real Q2.10 values
x = double(x_int) / fp;


fid = fopen('HW6_BPF_hex.txt', 'r');
coeffHex = textscan(fid, '%s');
fclose(fid);
coeffHex = coeffHex{1};

%Convert hex strings to signed 16-bit ints (Q1.15)
h_int = zeros(length(coeffHex), 1);
for k = 1:length(coeffHex)
    %Take each binary input and convert to decimal
    u = hex2dec(coeffHex{k});
    if u >= 2^(WC-1)            %If the sign bit is 1..
        h_int(k) = u - 2^WC;    %If negative, subtract by MSB value
    else
        h_int(k) = u;           %If positive, keep the same
    end
end

h = h_int;                      %Q1.15 integer coefficients
N = length(h);

%MATLAB fixed-point FIR (Q2.10 * Q1.15 = Q3.25 >>> 15 = Q2.10)
y_int = conv(x_int, h);              %Slides h through and multiplies each coeff with a given x and sums the result
y_int = floor(y_int / 2^15);         %Shift by 15 since WF1+WF2=10+15=25 to return back to Q2.10
matlab_fir_out = double(y_int) / fp; %Divide by 2^10 to get real values of Q2.10 format


%Load decimal Verilog Q2.10 integer outputs
verilog_fir_reg_int = load('tmp_fir_out.txt');          %SRL_REG = 0
verilog_fir_srl_int = load('tmp_fir_srl_out.txt');      %SRL_REG = 1

%Convert to real values
verilog_fir_reg = double(verilog_fir_reg_int) / fp;
verilog_fir_srl = double(verilog_fir_srl_int) / fp;

%FIR delay 64 taps -> skip first 63 MATLAB outputs
delay = 63;   %So we start at matlab_fir_out(64)

%Find minimum length of all outputs
len = min([ ...
    length(x), ...
    length(verilog_fir_reg), ...
    length(verilog_fir_srl), ...
    length(matlab_fir_out) - delay ...
]);

%Build aligned signals
x_plot            = x(1:len);                             %Raw input samples
verilog_reg_plot  = verilog_fir_reg(1:len);               %Verilog FIR (reg)
verilog_srl_plot  = verilog_fir_srl(1:len);               %Verilog FIR (SRL)
matlab_fir_plot   = matlab_fir_out(delay+1 : delay+len);  %Start at index 64

%Absolute differences from raw
diff_verilog = abs(x_plot - verilog_reg_plot);
diff_matlab  = abs(x_plot - matlab_fir_plot);


%Raw vs Verilog vs MATLAB
figure;
subplot(2,1,1);
plot(x_plot, 'k'); hold on;
plot(verilog_reg_plot, 'b');
plot(matlab_fir_plot, '--r');
plot(verilog_srl_plot, ':g');
title('Raw Signal vs Verilog FIR vs MATLAB FIR');
legend('Raw Signal','Verilog FIR','MATLAB FIR', 'Location','best');
xlabel('Sample Index');
ylabel('Amplitude');
grid on;

%Absolute difference of the two filters from the raw signal
subplot(2,1,2);
plot(diff_verilog, 'b'); hold on;
plot(diff_matlab, 'r');
title('Absolute Difference From Raw Signal');
legend('|Raw - Verilog FIR|','|Raw - MATLAB FIR|', 'Location','best');
xlabel('Sample Index');
ylabel('Absolute Difference');
grid on;