verilog = readmatrix('cordic_output.txt');
angle_gen = linspace(0, 360, 512);
angle_d = verilog(:,1);
cosine_v = verilog(:,2)/512;
sine_v = verilog(:,3)/512;


K = 9950;       %K in integer fixed point with WF = 14
L = 10;
rot = 36;
scale = 512/pi;
a = 0;
size = L;
count = 1;

%Calculates the arctan values scaled by (512/pi) to keep bounds [-512, 511]
for i = 1:L
    atan_vals(i) = atan(2^-(i-1));
    atan_vals_fp(i) = round(atan_vals(i)*scale);
end


for i = 1:rot
    %Increment 10 degrees every iteration
    a = a + 28;

    %Handles automatic wrapping of angle (a) after surpassing 512
    a = mod(a + 512, 1024) - 512;

    %If in Q2 flip x and normalize z to keep it in Q1/Q4
    if(a >= 256)
        x = -K;
        y = 0;
        z = a - 512;
    %If in Q3 flip x and normalize z to keep it in Q1/Q4
    elseif(a <= -256)
        x = -K;
        y = 0;
        z = a + 512;
    %If in Q1/Q4 keep everything as is
    else
        x = K;
        y = 0;
        z = a;
    end

for itert = 0:L-1;
    %Move angle clockwise to readjust
    if(z >= 0)
        x_rot = x - bitsra(y, itert);
        y_rot = y + bitsra(x, itert);
        z = z - atan_vals_fp(itert+1);
    %Move angle counter-clockwise to readjust
    elseif(z < 0)
        x_rot = x + bitsra(y, itert);
        y_rot = y - bitsra(x, itert);
        z = z + atan_vals_fp(itert+1);        
    end
    x = x_rot;
    y = y_rot;
end
    cosine(count) = bitsra(x, 5)/512;
    sine(count) = bitsra(y, 5)/512;
    count = count + 1;
end

%Comparing sine outputs
subplot(3,1,1);
plot(angle_d, sine_v, 'r--o'); hold on;
plot(angle_d, sine, 'b');
title('Sine: Verilog vs MATLAB');
legend('Verilog','MATLAB');
grid on;

%Comparing cosine outputs
subplot(3,1,2);
plot(angle_d, cosine_v, 'r--o'); hold on;
plot(angle_d, cosine, 'b');
title('Cosine: Verilog vs MATLAB');
legend('Verilog','MATLAB');
grid on;

%Error between Verilog and Matlab Sine/Cosine
subplot(3,1,3);
plot(angle_d, abs(sine_v - sine), 'r'); hold on;
plot(angle_d, abs(cosine_v - cosine), 'b');
title('Absolute Error (Sine & Cosine)');
legend('|Sin Error|','|Cos Error|');
grid on;

%Calculate absolute error
cos_error = abs(cosine_v - cosine);
sin_error = abs(sine_v - sine);

%Combine results in table
output_results = [angle_d, cosine_v, sine_v, cosine, sine, cos_error, sin_error];

%Export results to matlab_output.txt
writematrix(output_results, 'cordic_matlab_output.txt', 'Delimiter', '\t');