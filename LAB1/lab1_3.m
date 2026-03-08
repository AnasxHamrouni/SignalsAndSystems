t = linspace( -10, 10, 201);

x0 = t .* exp( -abs(t) );

figure;
subplot(2,2, 1);
plot(t, x0);
grid on;
title('x_0(t)');
xlabel('t'); ylabel('x_0(t)');

xe = abs(t) .* exp( -abs(t) );
subplot(2,2,2);
plot(t, xe);
grid on;
title('x_e(t)');
xlabel('t'); ylabel('x_e(t)');

x = 0.5 .* (xe + x0);
subplot(2,2,3);
plot(t, x);
grid on;
title('x(t) = 0.5(x_e + x_0)');
xlabel('t'); ylabel('x(t)');

t = linspace(0, 1, 101);

x1 = exp(j * 10 * pi * t);

x1_real = real(x1);
x1_imag = imag(x1);

figure;
plot(t, x1_real, 'b');
hold on;
plot(t, x1_imag, 'r--');
hold off;

grid on;
xlabel('t');
ylabel('Amplitude');
title('Real and imaginary parts of x_1(t) = e^{j10\pi t}');
legend('Re\{x_1(t)\}', 'Im\{x_1(t)\}');

