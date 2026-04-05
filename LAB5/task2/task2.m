L = 5;
wc_max = pi/L;          % theoretical max cut-off
wc = 0.9 * wc_max;  

%% 2.2 
L = 5;
wc_max = pi/L;          
wc     = 0.8*wc_max; 

f_pass = wc/pi;         
f_stop = 1.0;           

Nfir = 80; 

h = firpm(Nfir, [0 f_pass f_stop 1], [1 1 0 0]);

% Plot magnitude and phase 
[H, w_freqz] = freqz(h, 1, 1024);
figure;
subplot(2,1,1);
plot(w_freqz, abs(H));
xlabel('Frequency (rad/sample)');
ylabel('Magnitude');
title('Anti-aliasing FIR magnitude response');
grid on;
subplot(2,1,2);
plot(w_freqz, angle(H));
xlabel('Frequency (rad/sample)');
ylabel('Phase (rad)');
title('Anti-aliasing FIR phase response');
grid on;

%% 2.3 Filter speechNoisy using conv
speechNoisyAa = conv(speechNoisy, h);
N_Aa = length(speechNoisyAa);
n_Aa = 0:N_Aa-1;

%% 2.4 
XAa = fft(speechNoisyAa);
w_Aa = linspace(-pi, pi, N_Aa);
XAa_shift = fftshift(XAa);
figure;
plot(w_Aa, abs(XAa_shift));
xlabel('Frequency (rad/sample)');
ylabel('Magnitude');
title('Magnitude spectrum of speechNoisyAa (after anti-aliasing filter)');
grid on;

%% 2.5 
speechNoisyAa_ds = speechNoisyAa(1:L:end);
fs_ds = fs / L;

%% 2.6 
soundsc(speechNoisyAa_ds, fs_ds);
N_ds = length(speechNoisyAa_ds);
X_ds = fft(speechNoisyAa_ds);
w_ds = linspace(-pi, pi, N_ds);
X_ds_shift = fftshift(X_ds);
figure;
plot(w_ds, abs(X_ds_shift));
xlabel('Frequency (rad/sample)');
ylabel('Magnitude');
title('Magnitude spectrum of downsampled speechNoisyAa');
grid on;

%% 2.7 
n_ds_Aa = 1:L:N_Aa;
n_full_Aa = 1:N_Aa;
speechNoisyAa_recon = interp1(n_ds_Aa, speechNoisyAa_ds, n_full_Aa, 'linear', 0).';
N_common = min(length(speech), length(speechNoisyAa_recon));
speech_trim = speech(1:N_common);
speechNoisyAa_recon_trim = speechNoisyAa_recon(1:N_common);
soundsc(speech_trim, fs);
pause(2); 
soundsc(speechNoisyAa_recon_trim, fs);
% Plot spectrum of reconstructed anti-aliased signal
X_Aa_re = fft(speechNoisyAa_recon_trim);
N_Aa_re = length(speechNoisyAa_recon_trim);
w_Aa_re = linspace(-pi, pi, N_Aa_re);
X_Aa_re_shift = fftshift(X_Aa_re);
figure;
plot(w_Aa_re, abs(X_Aa_re_shift));
xlabel('Frequency (rad/sample)');
ylabel('Magnitude');
title('Magnitude spectrum of reconstructed signal with anti-aliasing');
grid on;
