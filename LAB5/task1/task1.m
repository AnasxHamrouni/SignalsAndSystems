load('lab5data.mat');   
fs = 44100;             
N  = length(speech);
n  = 0:N-1;

%% 1.2 
P_speech = (speech'*speech)/N;

%% 1.3 
f0   = 5000;                   
% A^2/2 = 0.1 * P_speech
A    = sqrt(2 * 0.1 * P_speech);       
tone = A*cos(2*pi*f0*n/fs).';         
speechNoisy = speech + tone;

%% 1.4 
soundsc(speechNoisy, fs);           

% FFT-based spectrum
Xn = fft(speechNoisy);
w  = linspace(-pi, pi, N);           
Xn_shift = fftshift(Xn);
figure;
plot(w, abs(Xn_shift));
xlabel('Frequency (rad/sample)');
ylabel('Magnitude');
title('Magnitude spectrum of speechNoisy');
grid on;

%% 1.5 Downsample noisy signal
L = 5;
speechNoisy_ds = speechNoisy(1:L:end);
fs_ds=fs/L;               
soundsc(speechNoisy_ds, fs_ds);      

%% 1.6 
n_ds = 1:L:N;                          
n_full = 1:N;                         
speechNoisy_recon = interp1(n_ds, speechNoisy_ds, n_full, 'linear', 0).'; 

%% 1.7 
soundsc(speechNoisy_recon, fs);       
Xre = fft(speechNoisy_recon);
Xre_shift = fftshift(Xre);
figure;
plot(w, abs(Xre_shift));
xlabel('Frequency (rad/sample)');
ylabel('Magnitude');
title('Magnitude spectrum of reconstructed speechNoisy');
grid on;



