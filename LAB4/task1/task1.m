Fs = 256;                 
load('ECG.mat');          
x = ECG(:);               
N = length(x);
t = (0:N-1)/Fs; 

X = (1/N)*fft(x);% DTFS coefficients
k = -floor(N/2):(N-1-floor(N/2));% integer index
X_shift = fftshift(X);

figure;
stem(k, abs(X_shift), 'filled');
xlabel('k');
ylabel('|X[k]|');
title('Magnitude of DTFS coefficients of ECG');
grid on;
saveas(gcf, 'ECG_DTFS_mag.png');

%%
X_fft = fft(x);
omega = (-floor(N/2):(N-1-floor(N/2)))*(2*pi/N);

figure;
plot(omega, fftshift(abs(X_fft)));
xlabel('\omega (rad/sample)');
ylabel('|X(e^{j\omega})| (approx.)');
title('Approximate DTFT magnitude of ECG');
grid on;
saveas(gcf, 'ECG_DTFT_mag_rad_per_sample.png');

%%
% frequency axis in Hz
f = (-floor(N/2):(N-1-floor(N/2)))*(Fs/N);

figure;
plot(f, fftshift(abs(X_fft)));
xlabel('f (Hz)');
ylabel('|X(f)| (approx.)');
title('Approximate continuous-time spectrum of ECG');
grid on;
saveas(gcf, 'ECG_spectrum_Hz.png');

%%
T_window = 2.5;                        
idx_end = min(round(T_window*Fs), N);

figure;
plot(t(1:idx_end), x(1:idx_end));
xlabel('Time (s)');
ylabel('ECG amplitude');
title('ECG signal in time domain');
grid on;
saveas(gcf, 'ECG_time_segment.png');


