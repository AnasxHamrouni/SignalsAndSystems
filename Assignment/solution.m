
%% ============================================================
%  VUVUZELA REMOVAL - FINAL VERSION WITH LOGGING & PLOTS
% ============================================================

clear; close all; clc;
fprintf('--- FINAL VUVUZELA REMOVAL WITH ANALYSIS ---\n');

%% ============================================================
%  LOAD AUDIO
% ============================================================

[noisy, Fs] = audioread('noisy_audio.wav');
[vuv, ~]    = audioread('vuvuzela_example.wav');

if size(noisy,2) > 1, noisy = mean(noisy,2); end
if size(vuv,2) > 1, vuv = mean(vuv,2); end

%% ============================================================
%  PARAMETERS
% ============================================================

frame_size = 1024;
hop = 512;
window = hamming(frame_size, 'periodic');
Nfft = frame_size;

L = length(noisy);
freqs = (0:Nfft-1)' * (Fs/Nfft);

f0 = 235; % fundamental frequency

%% ============================================================
%  LOGGING SETUP
% ============================================================

log = struct();
log.params.frame_size = frame_size;
log.params.hop = hop;
log.params.Nfft = Nfft;
log.params.f0 = f0;

fprintf('\n--- PARAMETERS ---\n');
disp(log.params);

%% ============================================================
%  FRAME SIGNALS
% ============================================================

frames_noisy = buffer(noisy, frame_size, frame_size-hop, 'nodelay');

if length(vuv) < frame_size
    vuv = repmat(vuv, ceil(frame_size/length(vuv)), 1);
end

frames_noise = buffer(vuv, frame_size, frame_size-hop, 'nodelay');

num_frames = size(frames_noisy,2);

%% ============================================================
%  NOISE PSD ESTIMATION
% ============================================================

noise_psd = zeros(Nfft,1);

for i = 1:size(frames_noise,2)
    nf = frames_noise(:,i) .* window;
    NF = fft(nf, Nfft);
    noise_psd = noise_psd + abs(NF).^2;
end

noise_psd = noise_psd / size(frames_noise,2);

fprintf('Noise profile estimated\n');

%% ============================================================
%  MAIN PROCESSING
% ============================================================

output = zeros(L,1);
wsum   = zeros(L,1);
prev_H = ones(Nfft,1);

for i = 1:num_frames
    
    idx1 = (i-1)*hop + 1;
    idx2 = min(idx1 + frame_size - 1, L);
    valid_len = idx2 - idx1 + 1;
    
    frame = frames_noisy(:,i) .* window;
    X = fft(frame, Nfft);
    
    mag = abs(X);
    psd = mag.^2;
    
    if i == 1
        log.debug.first_frame_psd = psd;
        log.debug.noise_psd = noise_psd;
    end
    
    % Wiener filter
    alpha = 0.5;
    beta = 0.05;
    
    H = psd ./ (psd + alpha * noise_psd + 1e-10);
    H = max(H, beta);
    
    H = medfilt1(H, 9);
    H = 0.85 * prev_H + 0.15 * H;
    prev_H = H;
    
    % Harmonic suppression
    harmonic_mask = ones(Nfft,1);
    
    for h = 1:6
        fk = h * f0;
        bw = 100;
        sigma = bw / 2;
        
        notch = exp(-(abs(freqs - fk).^2)/(2*sigma^2)) + ...
                exp(-(abs(freqs - (Fs - fk)).^2)/(2*sigma^2));
        
        harmonic_mask = harmonic_mask .* (1 - 0.4 * notch);
    end
    
    gain = H .* harmonic_mask;
    
    Y = gain .* X;
    y = real(ifft(Y));
    
    output(idx1:idx2) = output(idx1:idx2) + y(1:valid_len).*window(1:valid_len);
    wsum(idx1:idx2)   = wsum(idx1:idx2) + window(1:valid_len).^2;
    
    log.energy_in(i)  = sum(frame.^2);
    log.energy_out(i) = sum(y.^2);
end

filtered = output ./ max(wsum,1e-12);

%% ============================================================
%  NOTCH FILTERS
% ============================================================

y_eq = filtered;

for h = 1:6
    fk = h * f0;
    w0 = 2*pi*fk/Fs;
    
    Q = 20;
    r = 0.97;
    
    b = [1, -2*cos(w0), 1];
    a = [1, -2*r*cos(w0), r^2];
    
    y_eq = filtfilt(b, a, y_eq);
end

filtered = y_eq;

%% ============================================================
%  MULTIBAND COMPRESSION
% ============================================================

[b,a] = butter(2, [200 1000]/(Fs/2), 'bandpass');
band = filtfilt(b,a,filtered);

threshold = 0.1;
ratio = 4;

compressed = band;
idx = abs(band) > threshold;
compressed(idx) = threshold + (band(idx)-threshold)/ratio;

filtered = filtered - band + compressed;

%% ============================================================
%  LOUDNESS RESTORATION
% ============================================================

filtered = filtered * (rms(noisy)/rms(filtered));
filtered = filtered / max(abs(filtered));

[b_s, a_s] = butter(2, [1000 4000]/(Fs/2), 'bandpass');
speech_band = filtfilt(b_s, a_s, filtered);

filtered = filtered + 0.25 * speech_band;

%% ============================================================
%  PERCEPTUAL MASKING
% ============================================================

rng(0);
noise_floor = randn(size(filtered));

[bp_b, bp_a] = butter(2, [300 3000]/(Fs/2), 'bandpass');
noise_floor = filtfilt(bp_b, bp_a, noise_floor);

filtered = filtered + 0.002 * noise_floor;

%% ============================================================
%  FINAL NORMALIZATION
% ============================================================

filtered = filtered / max(abs(filtered));
filtered = 1.2 * filtered;
filtered = filtered / max(abs(filtered));

%% ============================================================
%  PERFORMANCE METRICS
% ============================================================

processing_delay = frame_size / Fs;
snr_est = 10*log10(var(noisy)/var(noisy-filtered));

fprintf('\n--- PERFORMANCE ---\n');
fprintf('Estimated delay: %.4f seconds\n', processing_delay);
fprintf('Approx SNR improvement: %.2f dB\n', snr_est);

%% ============================================================
%  PLOTS
% ============================================================

% Time domain
figure;
subplot(2,1,1); plot(noisy); title('Noisy Signal');
subplot(2,1,2); plot(filtered); title('Filtered Signal');

% Spectrogram
figure;
subplot(2,1,1);
spectrogram(noisy, hamming(1024), 512, 1024, Fs, 'yaxis');
title('Noisy Spectrogram');

subplot(2,1,2);
spectrogram(filtered, hamming(1024), 512, 1024, Fs, 'yaxis');
title('Filtered Spectrogram');

% PSD comparison
figure;
plot(freqs, 10*log10(noise_psd+1e-10),'r'); hold on;
plot(freqs, 10*log10(log.debug.first_frame_psd+1e-10),'b');
legend('Noise PSD','Signal PSD');
title('PSD Comparison'); xlabel('Hz'); ylabel('dB');

% Wiener gain
figure;
plot(freqs, H);
title('Wiener Gain'); xlabel('Hz');

% Harmonic mask
figure;
plot(freqs, harmonic_mask);
title('Harmonic Suppression Mask'); xlabel('Hz');

%% ============================================================
%  REFINED FILTER FREQUENCY RESPONSES (MAG + PHASE)
% ============================================================

figure;

% Frequency axis
[H_total, w] = freqz(1,1,4096,Fs);

% Build combined notch filter
b_total = 1;
a_total = 1;

for h = 1:6
    fk = h * f0;
    w0 = 2*pi*fk/Fs;
    
    r = 0.97;
    
    b = [1 -2*cos(w0) 1];
    a = [1 -2*r*cos(w0) r^2];
    
    % Convolve to combine filters
    b_total = conv(b_total, b);
    a_total = conv(a_total, a);
end

% Compute total response
[H_total, w] = freqz(b_total, a_total, 4096, Fs);

% ---------- Magnitude ----------
subplot(2,1,1);
plot(w, 20*log10(abs(H_total)+1e-12), 'LineWidth', 1.5);
grid on;
xlabel('Frequency (Hz)');
ylabel('Magnitude (dB)');
title('Combined Notch Filter - Magnitude Response');
xlim([0 2000]);

% Mark harmonic frequencies
hold on;
for h = 1:6
    xline(h*f0, '--r', ['h', num2str(h)]);
end

% ---------- Phase ----------
subplot(2,1,2);
plot(w, unwrap(angle(H_total)), 'LineWidth', 1.5);
grid on;
xlabel('Frequency (Hz)');
ylabel('Phase (radians)');
title('Combined Notch Filter - Phase Response');
xlim([0 2000]);
%% ============================================================
%  PLAYBACK & SAVE
% ============================================================

disp('Processed...');
sound(filtered, Fs);

audiowrite('final_output_enhanced.wav', filtered, Fs);
fprintf('Saved final_output_enhanced.wav\n');