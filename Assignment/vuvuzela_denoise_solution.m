%% ============================================================
%  VUVUZELA NOISE REDUCTION (MATLAB VERSION OF PYTHON NOTEBOOK)
% ============================================================

clear; close all; clc;
fprintf('--- VUVUZELA DENOISE PIPELINE (MATLAB) ---\n');

%% Paths and output folders
base_dir = fileparts(mfilename('fullpath'));
noisy_path = fullfile(base_dir, 'noisy_audio.wav');
vuv_path   = fullfile(base_dir, 'vuvuzela_example.wav');

artifacts_dir = fullfile(base_dir, 'artifacts');
audio_dir = fullfile(artifacts_dir, 'audio');
plot_dir  = fullfile(artifacts_dir, 'plots');
if ~exist(audio_dir, 'dir'), mkdir(audio_dir); end
if ~exist(plot_dir, 'dir'), mkdir(plot_dir); end

%% Load audio
[noisy, fs_noisy] = audioread(noisy_path);
[vuv, fs_vuv]     = audioread(vuv_path);

if size(noisy,2) > 1, noisy = mean(noisy,2); end
if size(vuv,2) > 1, vuv = mean(vuv,2); end

% Match sampling rates if needed
if fs_vuv ~= fs_noisy
    vuv = resample(vuv, fs_noisy, fs_vuv);
end

fs = fs_noisy;
noisy = noisy(:);
vuv = vuv(:);

t_noisy = (0:length(noisy)-1)' / fs;
t_vuv = (0:length(vuv)-1)' / fs;

fprintf('Noisy: %d samples, %.2f s @ %d Hz\n', length(noisy), length(noisy)/fs, fs);
fprintf('Vuvuzela sample: %d samples, %.2f s @ %d Hz\n', length(vuv), length(vuv)/fs, fs);

%% Plot: input time domain
fig = figure('Color','w','Name','Input Time Domain');
subplot(2,1,1);
plot(t_noisy, noisy, 'LineWidth', 0.8); grid on;
title('Noisy Audio (Time Domain)'); xlabel('Time (s)'); ylabel('Amplitude');

subplot(2,1,2);
plot(t_vuv, vuv, 'LineWidth', 0.8); grid on;
title('Vuvuzela Reference (Time Domain)'); xlabel('Time (s)'); ylabel('Amplitude');

saveas(fig, fullfile(plot_dir, 'mat_01_time_domain_inputs.png'));

%% Fundamental estimation from vuvuzela reference
npsd = 4096;
overlap_psd = 2048;

[P_vuv, f_psd] = pwelch(vuv, hann(npsd,'periodic'), overlap_psd, npsd, fs, 'onesided');
P_vuv_db = 10*log10(P_vuv + 1e-18);

search_idx = (f_psd >= 150) & (f_psd <= 450);
f0 = 235.0;
if any(search_idx)
    [pk, loc] = findpeaks(P_vuv_db(search_idx), 'SortStr', 'descend');
    if ~isempty(pk)
        f_candidates = f_psd(search_idx);
        f0 = f_candidates(loc(1));
    end
end

num_harmonics = 8;
harmonics = f0 * (1:num_harmonics);
harmonics = harmonics(harmonics < fs/2);

fprintf('Estimated f0: %.2f Hz\n', f0);
fprintf('Harmonics (Hz): %s\n', mat2str(round(harmonics,2)));

fig = figure('Color','w','Name','Vuvuzela Harmonics');
plot(f_psd, P_vuv_db, 'LineWidth', 1.0); hold on; grid on;
for i = 1:length(harmonics)
    xline(harmonics(i), '--r', sprintf('h%d', i));
end
xlim([0 min(2000, fs/2)]);
title('Harmonic Structure of Vuvuzela');
xlabel('Frequency (Hz)'); ylabel('Magnitude (dB/Hz)');
saveas(fig, fullfile(plot_dir, 'mat_02_vuv_harmonic_structure.png'));

%% Plot: noisy vs vuvuzela spectrum comparison
[P_noisy_ref, f_n] = pwelch(noisy, hann(npsd,'periodic'), overlap_psd, npsd, fs, 'onesided');
[P_vuv_ref, f_v]   = pwelch(vuv,   hann(npsd,'periodic'), overlap_psd, npsd, fs, 'onesided');

fig = figure('Color','w','Name','Spectrum Comparison');
plot(f_n, 10*log10(P_noisy_ref + 1e-18), 'LineWidth', 0.9); hold on;
plot(f_v, 10*log10(P_vuv_ref + 1e-18), 'LineWidth', 0.9); grid on;
xlim([0 min(2000, fs/2)]);
legend('Noisy Signal', 'Vuvuzela Only', 'Location', 'best');
title('Spectrum Comparison (Used for Filter Design)');
xlabel('Frequency (Hz)'); ylabel('Magnitude (dB)');
saveas(fig, fullfile(plot_dir, 'mat_03_spectrum_design_comparison.png'));

%% STFT Wiener + harmonic suppression + residual-tone control
n_fft = 1024;
hop = 256;
overlap = n_fft - hop;
win = hann(n_fft, 'periodic');

[Z_noisy, f_stft_n, t_stft_n] = stft(noisy, fs, ...
    'Window', win, 'OverlapLength', overlap, 'FFTLength', n_fft, 'FrequencyRange', 'onesided');
[Z_vuv, f_stft_v, t_stft_v] = stft(vuv, fs, ...
    'Window', win, 'OverlapLength', overlap, 'FFTLength', n_fft, 'FrequencyRange', 'onesided');

S_noisy = abs(Z_noisy).^2;
S_noise = abs(Z_vuv).^2;
noise_psd = mean(S_noise, 2) + 1e-12;
noise_psd_col = noise_psd;

% Aggressive denoising controls for maximum buzz removal
alpha = 1.35;
oversub = 1.25;
sub_floor = 0.02;
gain_floor = 0.03;
time_smooth = 0.82;

% Harmonic controls
harmonic_depth = 0.88;
harmonic_bw_hz = 56.0;

% Wiener gain
H_wiener = S_noisy ./ (S_noisy + alpha * noise_psd_col + 1e-12);
H_wiener = min(max(H_wiener, gain_floor), 1.0);
H_wiener = medfilt1(H_wiener, 7, [], 1, 'truncate');

% Spectral subtraction gain
S_sub = max(S_noisy - oversub * noise_psd_col, sub_floor * noise_psd_col);
H_sub = sqrt(S_sub ./ (S_noisy + 1e-12));

% Temporal smoothing
for n = 2:size(H_wiener,2)
    H_wiener(:,n) = time_smooth * H_wiener(:,n-1) + (1 - time_smooth) * H_wiener(:,n);
end

% Harmonic suppression mask with sidebands
F = repmat(f_stft_n, 1, size(H_wiener,2));
harmonic_mask = ones(size(H_wiener));
for k = 1:length(harmonics)
    fh = harmonics(k);
    g_main = exp(-0.5 * ((F - fh) / harmonic_bw_hz).^2);
    g_low  = exp(-0.5 * ((F - max(0.0, fh - 0.45*f0)) / (0.8*harmonic_bw_hz)).^2);
    g_high = exp(-0.5 * ((F - (fh + 0.45*f0)) / (0.8*harmonic_bw_hz)).^2);
    g = max(g_main, max(g_low, g_high));
    harmonic_mask = harmonic_mask .* (1.0 - harmonic_depth * g);
end
harmonic_mask = min(max(harmonic_mask, 0.08), 1.0);

% Extra tone gate from learned vuvuzela profile
tone_profile = noise_psd_col / max(noise_psd_col);
tone_gate_strength = 1.25;
H_tone = 1.0 ./ (1.0 + tone_gate_strength * tone_profile);
H_tone = repmat(H_tone, 1, size(H_wiener,2));

H_total = H_wiener .* H_sub .* harmonic_mask .* H_tone;
H_total = min(max(H_total, 0.03), 1.0);

Z_stage1 = H_total .* Z_noisy;
y_stage1 = istft(Z_stage1, fs, ...
    'Window', win, 'OverlapLength', overlap, 'FFTLength', n_fft, 'FrequencyRange', 'onesided');
y_stage1 = y_stage1(:);
if length(y_stage1) < length(noisy)
    y_stage1(end+1:length(noisy)) = 0;
end
y_stage1 = y_stage1(1:length(noisy));

%% Adaptive notch cascade + post-STFT de-buzz
y_notch = y_stage1;

Q = 16.0;
drift_hz = 12.0;
for k = 1:length(harmonics)
    fh = harmonics(k);
    centers = [fh - drift_hz, fh, fh + drift_hz];
    for c = 1:length(centers)
        fc = centers(c);
        if fc > 40 && fc < (fs/2 - 40)
            w0_rad = 2*pi*fc/fs;
            r = 1 - (fc/(fs/2)) / (2*Q);
            r = min(max(r, 0.90), 0.9999);
            b_notch = [1, -2*cos(w0_rad), 1];
            a_notch = [1, -2*r*cos(w0_rad), r^2];
            y_notch = filtfilt(b_notch, a_notch, y_notch);
        end
    end
end

% Mild speech presence boost
[b_bp, a_bp] = butter(2, [1000 3500]/(fs/2), 'bandpass');
speech_band = filtfilt(b_bp, a_bp, y_notch);
y_enh = y_notch + 0.20 * speech_band;

% Low-frequency cleanup
[b_hp, a_hp] = butter(2, 90/(fs/2), 'high');
y_enh = filtfilt(b_hp, a_hp, y_enh);

% Post-STFT residual de-buzz gate
[Z_post, f_post, t_post] = stft(y_enh, fs, ...
    'Window', win, 'OverlapLength', overlap, 'FFTLength', n_fft, 'FrequencyRange', 'onesided');
P_post = abs(Z_post).^2;
noise_floor_post = prctile(P_post, 20, 2);

post_strength = 1.45;
H_post = (P_post - post_strength * noise_floor_post) ./ (P_post + 1e-12);
H_post = min(max(H_post, 0.20), 1.0);

F_post = repmat(f_post, 1, size(H_post,2));
harm_post = ones(size(H_post));
for k = 1:length(harmonics)
    fh = harmonics(k);
    g = exp(-0.5 * ((F_post - fh) / 56.0).^2);
    harm_post = harm_post .* (1.0 - 0.28 * g);
end
harm_post = min(max(harm_post, 0.18), 1.0);

H_post_total = H_post .* harm_post;
H_post_total = min(max(H_post_total, 0.16), 1.0);

y_post = istft(H_post_total .* Z_post, fs, ...
    'Window', win, 'OverlapLength', overlap, 'FFTLength', n_fft, 'FrequencyRange', 'onesided');
y_post = y_post(:);
if length(y_post) < length(noisy)
    y_post(end+1:length(noisy)) = 0;
end
y_enh = y_post(1:length(noisy));

% Loudness match + peak normalize
y_enh = y_enh * (rms(noisy)/(rms(y_enh)+1e-12));
y_enh = 0.98 * y_enh / (max(abs(y_enh))+1e-12);

fprintf('Input RMS:  %.6f\n', rms(noisy));
fprintf('Output RMS: %.6f\n', rms(y_enh));

%% Quantitative proxies (no clean reference)
[P_out, f_out] = pwelch(y_enh, hann(npsd,'periodic'), overlap_psd, npsd, fs, 'onesided');

speech_band_hz = [300 3400];
low_band_hz = [0 180];
harm_bw = 30.0;

speech_in = bandpower_psd(P_noisy_ref, f_n, speech_band_hz(1), speech_band_hz(2));
speech_out = bandpower_psd(P_out, f_out, speech_band_hz(1), speech_band_hz(2));
low_in = bandpower_psd(P_noisy_ref, f_n, low_band_hz(1), low_band_hz(2));
low_out = bandpower_psd(P_out, f_out, low_band_hz(1), low_band_hz(2));

harm_in = 0;
harm_out = 0;
for k = 1:length(harmonics)
    f1 = max(0, harmonics(k)-harm_bw);
    f2 = harmonics(k)+harm_bw;
    harm_in = harm_in + bandpower_psd(P_noisy_ref, f_n, f1, f2);
    harm_out = harm_out + bandpower_psd(P_out, f_out, f1, f2);
end

speech_change_db = 10*log10((speech_out+1e-18)/(speech_in+1e-18));
low_change_db = 10*log10((low_out+1e-18)/(low_in+1e-18));
harm_change_db = 10*log10((harm_out+1e-18)/(harm_in+1e-18));

fprintf('\n--- Proxy Metrics ---\n');
fprintf('Speech band power change (300-3400 Hz): %.2f dB\n', speech_change_db);
fprintf('Low band power change (0-180 Hz):      %.2f dB\n', low_change_db);
fprintf('Harmonic power change (around hf0):     %.2f dB\n', harm_change_db);

%% Visual evaluation
fig = figure('Color','w','Name','Time Result');
subplot(2,1,1);
plot((0:length(noisy)-1)/fs, noisy, 'LineWidth', 0.8); grid on;
title('Noisy Signal'); xlabel('Time (s)'); ylabel('Amplitude');

subplot(2,1,2);
plot((0:length(y_enh)-1)/fs, y_enh, 'LineWidth', 0.8); grid on;
title('Filtered Signal'); xlabel('Time (s)'); ylabel('Amplitude');

saveas(fig, fullfile(plot_dir, 'mat_04_time_domain_result.png'));

fig = figure('Color','w','Name','Spectrogram Result');
subplot(2,1,1);
spectrogram(noisy, hann(n_fft,'periodic'), overlap, n_fft, fs, 'yaxis');
title('Noisy Spectrogram'); ylim([0 5]);

subplot(2,1,2);
spectrogram(y_enh, hann(n_fft,'periodic'), overlap, n_fft, fs, 'yaxis');
title('Filtered Spectrogram'); ylim([0 5]);

saveas(fig, fullfile(plot_dir, 'mat_05_spectrogram_result.png'));

fig = figure('Color','w','Name','PSD Comparison');
plot(f_n, 10*log10(P_noisy_ref + 1e-18), 'LineWidth', 1.0); hold on;
plot(f_out, 10*log10(P_out + 1e-18), 'LineWidth', 1.0);
for k = 1:length(harmonics)
    xline(harmonics(k), '--k');
end
grid on;
xlim([0 min(4000, fs/2)]);
legend('Noisy PSD', 'Filtered PSD', 'Location', 'best');
title('PSD Comparison After Processing');
xlabel('Frequency (Hz)'); ylabel('PSD (dB/Hz)');
saveas(fig, fullfile(plot_dir, 'mat_06_psd_result.png'));

fig = figure('Color','w','Name','Adaptive Gain Heatmap');
imagesc(t_stft_n, f_stft_n, H_total); axis xy;
ylim([0 min(5000, fs/2)]);
colorbar; xlabel('Time (s)'); ylabel('Frequency (Hz)');
title('Adaptive Time-Frequency Gain');
saveas(fig, fullfile(plot_dir, 'mat_07_gain_heatmap.png'));

%% Save cleaned output
out_path = fullfile(audio_dir, 'final_output_matlab.wav');
audiowrite(out_path, y_enh, fs);
fprintf('\nSaved: %s\n', out_path);

%% Save summary JSON for report usage
summary = struct();
summary.fs = fs;
summary.f0_estimated_hz = f0;
summary.harmonics_hz = harmonics;
summary.alpha = alpha;
summary.oversub = oversub;
summary.gain_floor = gain_floor;
summary.harmonic_depth = harmonic_depth;
summary.harmonic_bw_hz = harmonic_bw_hz;
summary.tone_gate_strength = tone_gate_strength;
summary.Q = Q;
summary.drift_hz = drift_hz;
summary.post_strength = post_strength;
summary.speech_band_change_db = speech_change_db;
summary.low_band_change_db = low_change_db;
summary.harmonic_band_change_db = harm_change_db;

json_text = jsonencode(summary);
fid = fopen(fullfile(artifacts_dir, 'matlab_report_summary.json'), 'w');
fprintf(fid, '%s', json_text);
fclose(fid);

fprintf('Saved summary JSON to artifacts/matlab_report_summary.json\n');

%% Local helper function
function p = bandpower_psd(Pxx, f, f1, f2)
idx = (f >= f1) & (f <= f2);
if ~any(idx)
    p = 0;
    return;
end
p = trapz(f(idx), Pxx(idx));
end
