n0 = 0; n1= -5; n2= 5;

[u, n] = dtstep(n0, n1, n2)
x0 = exp(0.3 * n) .* u

figure;
stem(n , x0, 'filled');
xlabel('n');
ylabel('x_0');
title('x_0[n] = e^{0.3 n} u[n]');

[x11, n] = dtimpulse(-2, n1, n2)
[x12, n] = dtimpulse(4, n1, n2)
x1 = x11 - x12;

figure;
stem(n , x1, 'filled');
xlabel('n');
ylabel('x_1');
title('x_1[n] = \delta[n+2] - \delta[n-4]');

n1 = 0 ; n2 = 20;
[u1, n] = dtstep(n0, n1, n2)
[u2, n] = dtstep(10, n1, n2)
[u3, n] = dtstep(20, n1, n2)

x2 = n .* ( u1 - u2 ) + ( 10 * exp( -0.3 * (n-10) ) .* ( u2 - u3 ) )

figure;
stem(n , x2, 'filled');
xlabel('n');
ylabel('x_2');
title('x_2[n] = n(u[n] - u[n-10]) + 10e^{-0.3(n-10)}(u[n-10] - u[n-20])');

