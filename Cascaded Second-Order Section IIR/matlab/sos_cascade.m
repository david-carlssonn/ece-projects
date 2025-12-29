WF = 10; NB = 12;

%Binary Q2.10 -> real
lines = readlines('Neural_Signal_Sample.txt');
N = numel(lines);
x_int = zeros(N,1);
for k = 1:N
    s = char(strtrim(lines(k)));   %12-bit two's complement
    v = bin2dec(s);
    if s(1) == '1', v = v - 2^NB; end
    x_int(k) = v;
end
x = x_int / 2^WF;  % real Q2.10

%Load verilog output decimal Q2.10 -> real
yf_dec = readmatrix('sos_cascade_out.txt');
if max(abs(yf_dec)) > 2
    yf = yf_dec / 2^WF;
else
    yf = yf_dec;
end

%Compute MATLAB expected
D   = load('Quantized_LPF_SOS.mat');
sos = double(D.sos);
g   = double(D.g);
if any(abs(sos(:)) > 2), sos = sos / 2^14; end
if any(abs(g(:))   > 2), g   = g   / 2^14; end

%a0 normalization for MATLAB filter()
for k = 1:size(sos,1)
    a0 = sos(k,4);
    if a0 ~= 1
        sos(k,1:3) = sos(k,1:3) / a0;
        sos(k,4:6) = sos(k,4:6) / a0;
    end
end

%Floating-point expected cascade with gains
y_exp = g(1) * x;
M = size(sos,1);
for k = 1:M
    b = sos(k,1:3); a = sos(k,4:6);
    y_exp = filter(b, a, y_exp);
    y_exp = g(k+1) * y_exp;
end

%Align lengths and compute absolute error
L = min([numel(x), numel(yf), numel(y_exp)]);
x     = x(1:L);
yf    = yf(1:L);
y_exp = y_exp(1:L);
abs_err = abs(yf - y_exp);

figure('Color','w');

%Top: x, Verilog y, MATLAB expected y
subplot(2,1,1);
plot(x,     'k', 'DisplayName','Input x'); hold on;
plot(yf,    'r', 'DisplayName','Verilog y');
plot(y_exp, 'b', 'DisplayName','MATLAB expected y');
grid on; xlabel('Sample'); ylabel('Amplitude');
title('x, Verilog output, and MATLAB expected output');
legend('Location','best');

%Bottom: |error| vs x (so you can see error relative to input)
subplot(2,1,2);
plot(abs_err, 'm',  'DisplayName','|Verilog - MATLAB|'); hold on;
plot(x,       'k--','DisplayName','x (raw input)');
grid on; xlabel('Sample'); ylabel('Amplitude');
title('Absolute Error & Raw Input x');
legend('Location','best');


%Columns: x, MATLAB_y, Verilog_y, |MATLAB - x|, |Verilog - x|, |Verilog - MATLAB|
fname = 'sos_cascade_all_signals.txt';
fid = fopen(fname,'w');
fprintf(fid, 'x\tMATLAB_y\tVerilog_y\t|MATLAB-x|\t|Verilog-x|\t|Verilog-MATLAB|\n');
data = [x(:), y_exp(:), yf(:), abs(y_exp(:)-x(:)), abs(yf(:)-x(:)), abs_err(:)];
fprintf(fid, '%.10f\t%.10f\t%.10f\t%.10f\t%.10f\t%.10f\n', data.');
fclose(fid);

