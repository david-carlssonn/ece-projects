load('Quantized_LPF_SOS.mat')


WL = 16;
WF = 14; 


F = fimath('RoundingMethod','Nearest','OverflowAction','Saturate');
T = numerictype('Signed', true, 'WordLength', WL, 'FractionLength', WF);


fid_sos = fopen('SOS_binary.txt', 'w');
for i = 1:size(sos, 1)
    for j = 1:size(sos,2) 
        val = fi(sos(i,j), T, F);
        fprintf(fid_sos, '%s\n', val.bin);
    end
end
fclose(fid_sos);


fid_g = fopen('g_binary.txt', 'w');
for i = 1:numel(g)
    val = fi(g(i), T, F);
    fprintf(fid_g, '%s\n', val.bin);
end
fclose(fid_g);


