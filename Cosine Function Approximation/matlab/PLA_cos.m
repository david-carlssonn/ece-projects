xmin = 0;
xmax = 2*pi;
xLength = xmax - xmin;
numSegment = 64;
segmentSize = xLength/numSegment;
WF=12;
numPoints_X = 16000;
x = linspace(xmin, xmax, numPoints_X);

segmentCoeff = zeros(2, numSegment);
xSplit = mat2cell(x, 1, ones(1, numSegment) .* length(x)/numSegment);

for j = 1 : numSegment
    cX = xSplit{j};
    cY = cos(cX);
    p = polyfit(cX, cY, 1);
    segmentCoeff(:, j) = p';
end


function[segmentIndex] = SegmentDecoder(num, segmentVals)
    noSegments = length(segmentVals);
    segmentIndex = 0;
    for i = 1:noSegments
        currentSegmentVals = segmentVals{i};
        if num <= currentSegmentVals(end)
            segmentIndex = i;
            break;
        end
    end
end


function [y] = Compute_PLA_Gen(x, segCoeff, segX)
    y = zeros(size(x, 1), size(x, 2));
    for i = 1:length(x)
        SegmentIndex = SegmentDecoder(x(i), segX);
        if SegmentIndex ~= 0
            multCoeff = segCoeff(1, SegmentIndex);
            addCoeff  = segCoeff(2, SegmentIndex);
            y(i) = (x(i) * multCoeff) + addCoeff;
        else
            y(i) = 0;
        end
    end
end

fid = fopen('coeffROM.mem', 'w');

for i = 1:numSegment
    fixed_a = round(segmentCoeff(1,i) * 2^(WF-12));
    fixed_b = round(segmentCoeff(2,i) * 2^WF);

    fixed_a = mod(fixed_a, 2^16);
    fixed_b = mod(fixed_b, 2^16);

    fixed_a_bin = dec2bin(fixed_a, 16);
    fixed_b_bin = dec2bin(fixed_b, 16);
    fprintf(fid, "%s%s\n", fixed_a_bin, fixed_b_bin);
end

fclose(fid);

y_actual = cos(x);
y_approximate = Compute_PLA_Gen(x, segmentCoeff, xSplit);

subplot(2,1,1);
plot(x, y_actual, 'b');
hold on;
plot(x, y_approximate, 'r');
subplot(2,1,2);
stem(x, abs(y_actual - y_approximate));

mse = mean((y_actual - y_approximate).^2);


