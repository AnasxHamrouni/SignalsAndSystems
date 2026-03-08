n = 0:3
[x_delta, n_delta] = dtimpulse(0, 0, 3);
[x_step, n_step]  = dtstep(0, 0, 3);

[y_sum, n_out] = sumsys(x_delta, n_delta, x_step, n_step);

figure;
stem(n_out, y_sum);
title('delta[n] + u[n]');
xlabel('n');
ylabel('y[n]');



[delayed_imp , n_delayed] = delaysys(2, x_delta, n_delta)
figure;
stem(n_delayed, delayed_imp); hold on;
stem(n_delayed, delayed_imp, 'r');
legend('delta[n]', 'delta[n-2]');
title('Delay of delta[n] by N=2');
xlabel('n'); ylabel('value');

[delayed_imp2 , n_delayed2] = delaysys(4, x_delta, n_delta)
figure;
stem(n_delayed2, delayed_imp2); hold on;
stem(n_delayed2, delayed_imp2, 'r');
legend('delta[n]', 'delta[n-4]');
title('Delay of delta[n] by N=4');
xlabel('n'); ylabel('value');

load AUDUSD.mat;

[audout, naud] = threepointaverage(aud, taud);
figure;

subplot(2,1,1);
plot(taud, aud);
title('AUD to USD exchange rate (original)');
xlabel('Day');
ylabel('AUDUSD');
ylim([0.68 0.8]);

subplot(2,1,2);
plot(taud, audout);
title('AUD to USD exchange rate (3-point average)');
xlabel('Day');
ylabel('AUDUSD');
ylim([0.68 0.8]);

