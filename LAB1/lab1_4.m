fs = 8192;
ts = 3*fs + 1;
t = linspace(0, 3, ts);

xs = cos(2*pi*440*t);


ys = 2 .* xs;

%soundsc(ys, fs);

load handel

N = Fs*3 + 1;
y3 = y(1:N);
sound(y3, Fs);

ty3 = linspace(0, 3, length(y3)); 
plot(ty3, y3);
title('First three seconds of Hallelujah Chorus');
xlabel('t (seconds)');
ylabel('Amplitude');
