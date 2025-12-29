WF = 14;
N  = 256;

%Load Verilog results
y_down   = load('round_down.txt');
y_halfup = load('round_halfup.txt');
y_even   = load('round_even.txt');

%True cosine
x = linspace(0, 2*pi, N);
y_true = cos(x);

%True cosine vs rounded
subplot(2,1,1);
plot(x, y_true, 'k'); hold on;
plot(x, y_down, 'r');
plot(x, y_halfup, 'b');
plot(x, y_even, 'g');
xlabel('Angle (radians)');
ylabel('Cosine value');
title('True cosine vs rounded outputs (256 points)');
legend('True','Down','Half-up','Nearest even');
grid on;

%Absolute error
subplot(2,1,2);
plot(x, abs(y_down - y_true), 'r'); hold on;
plot(x, abs(y_halfup - y_true), 'b');
plot(x, abs(y_even - y_true), 'g');
xlabel('Angle (radians)');
ylabel('|Error|');
title('Absolute error (256 points)');
legend('Down','Half-up','Nearest even');
grid on;