D     = 6144;
alpha = 0.5;
[h, nh] = echoIR(D, alpha);

figure;
stem(nh, h, 'filled');
xlabel('n');
ylabel('h[n]');
title('Echo impulse response');
xlim([0 D]);

load handel;
ny = 0:(length(y)-1);

[yecho, nyecho] = myconv(y, ny, h, nh);
soundsc(yecho, Fs);

[yecho2, nyecho2] = myconv(yecho, nyecho, h, nh);
soundsc(yecho2, Fs);
