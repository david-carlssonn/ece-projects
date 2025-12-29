%Moving average w/ plots

L = 4;
L_2 = 8;
WL = 16;

%For loop to calculate average w/ L=4
for n = 1:length(sample_data)
mat_win = sample_data(max(1, n-L+1) : n);
sum_win = sum(mat_win);
avg_4(n) = sum_win / L;
end

%For loop to calculate average w/ L=8
for n = 1:length(sample_data)
mat_win = sample_data(max(1, n-L_2+1) : n);
sum_win = sum(mat_win);
avg_8(n) = sum_win / L_2;
end

%All decimal -> binary conversions
bin_avg_L4 = dec2bin(floor(avg_4), WL);
bin_avg_L8 = dec2bin(floor(avg_8), WL);
bin_input = dec2bin(sample_data, WL);

%Open .mem file to write to
bin_out_L4 = fopen("bin_matlab_avg_output L=4.mem", 'w');
bin_out_L8 = fopen("bin_matlab_avg_output L=8.mem", 'w');

%Write each average in binary to file
for i = 1:length(sample_data)
    fprintf(bin_out_L4, '%s\n', bin_avg_L4(i,:));
end
fclose(bin_out_L4);

%Write each average in binary to file
for i = 1:length(sample_data)
    fprintf(bin_out_L8, '%s\n', bin_avg_L8(i,:));
end
fclose(bin_out_L8);

%L=4 Plot
figure;
plot(sample_data, 'b'); hold on;
plot(avg_4, 'r');
legend('INPUT', 'MOVING AVERAGE L=4');

%L=8 Plot
figure;
plot(sample_data, 'b'); hold on;
plot(avg_8, 'r');
legend('INPUT', 'MOVING AVERAGE L=8');