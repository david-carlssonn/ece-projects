WF = 14;
N  = 256;

%Load Verilog results
y_down   = load('round_down.txt');
y_halfup = load('round_halfup.txt');
y_even   = load('round_even.txt');

%True cosine
x_full = linspace(0, 2*pi, N);
y_true_full = cos(x_full);

%Only uses 3 points for readability (0, pi/2, pi)
idx = [1, round(N/4), round(N/2)];
x = x_full(idx);
y_true = y_true_full(idx);
y_down = y_down(idx);
y_halfup = y_halfup(idx);
y_even = y_even(idx);

%True cosine vs rounded
subplot(2,1,1);
plot(x, y_true, 'ko-'); hold on;
plot(x, y_down, 'ro-');
plot(x, y_halfup, 'bo-');
plot(x, y_even, 'go-');
xlabel('Angle (radians)');
ylabel('Cosine value');
title('True cosine vs rounded outputs (3 points)');
legend('True','Down','Half-up','Nearest even');
grid on;

%Absolute error
subplot(2,1,2);
plot(x, abs(y_down - y_true), 'ro-'); hold on;
plot(x, abs(y_halfup - y_true), 'bo-');
plot(x, abs(y_even - y_true), 'go-');
xlabel('Angle (radians)');
ylabel('|Error|');
title('Absolute error (3 points)');
legend('Down','Half-up','Nearest even');
grid on;