% vuvuzela noise reduction

function vuvuzela_denoise_solution_octave()
clear; close all; clc;
fprintf('--- VUVUZELA DENOISE PIPELINE (OCTAVE) ---\n');

% loading signal package for filter design and filtfilt.
try
  pkg load signal;
catch
  fprintf('Warning: signal package could not be loaded automatically.\n');
end

required_fns = {'butter', 'filtfilt', 'resample'};
missing = {};
for ii = 1:numel(required_fns)
  if exist(required_fns{ii}, 'file') == 0
    missing{end+1} = required_fns{ii}; %#ok<AGROW>
  end
end

if ~isempty(missing)
  error(['Missing required functions: ' strjoin(missing, ', ') '. ' ...
         'Install/load signal package with: pkg install -forge signal; pkg load signal']);
end



% set paths
this_file = mfilename('fullpath');
if isempty(this_file)
  base_dir = pwd;
else
  base_dir = fileparts(this_file);
end
noisy_path = fullfile(base_dir, 'noisy_audio.wav');
vuv_path   = fullfile(base_dir, 'vuvuzela_example.wav');
artifacts_dir = fullfile(base_dir, 'artifacts');
audio_dir = fullfile(artifacts_dir, 'audio');
plot_dir  = fullfile(artifacts_dir, 'plots');
if exist(artifacts_dir, 'dir') == 0, mkdir(artifacts_dir); end
if exist(audio_dir, 'dir') == 0, mkdir(audio_dir); end
if exist(plot_dir, 'dir') == 0, mkdir(plot_dir); end




% load audio
[noisy, fs_noisy] = audioread(noisy_path);
[vuv, fs_vuv]     = audioread(vuv_path);
if columns(noisy) > 1, noisy = mean(noisy, 2); end
if columns(vuv) > 1, vuv = mean(vuv, 2); end
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




% plot input signals
fig = figure('Name', 'Input Time Domain');
subplot(2,1,1);
plot(t_noisy, noisy, 'LineWidth', 0.8); grid on;
title('Noisy Audio (Time Domain)'); xlabel('Time (s)'); ylabel('Amplitude');
subplot(2,1,2);
plot(t_vuv, vuv, 'LineWidth', 0.8); grid on;
title('Vuvuzela Reference (Time Domain)'); xlabel('Time (s)'); ylabel('Amplitude');
save_plot(fig, fullfile(plot_dir, 'mat_01_time_domain_inputs.png'));




% estimate harmonic structure
npsd = 4096;
overlap_psd = 2048;
win_psd = hanning(npsd, 'periodic');

[P_vuv, f_psd] = welch_psd_onesided(vuv, fs, npsd, overlap_psd, win_psd);
P_vuv_db = 10*log10(P_vuv + 1e-18);

search_idx = find(f_psd >= 150 & f_psd <= 450);
f0 = 235.0;
if ~isempty(search_idx)
  [~, local_idx] = max(P_vuv_db(search_idx));
  f0 = f_psd(search_idx(local_idx));
end

num_harmonics = 8;
harmonics = f0 * (1:num_harmonics);
harmonics = harmonics(harmonics < fs/2);

fprintf('Estimated f0: %.2f Hz\n', f0);
fprintf('Harmonics (Hz): %s\n', mat2str(round(harmonics*100)/100));

fig = figure('Name', 'Vuvuzela Harmonics');
plot(f_psd, P_vuv_db, 'LineWidth', 1.0); hold on; grid on;
for i = 1:length(harmonics)
  plot([harmonics(i) harmonics(i)], [min(P_vuv_db) max(P_vuv_db)], '--r');
  if harmonics(i) < 2000
    text(harmonics(i)+5, max(P_vuv_db)-3, sprintf('h%d', i), 'color', 'r');
  end
end
xlim([0 min(2000, fs/2)]);
title('Harmonic Structure of Vuvuzela');
xlabel('Frequency (Hz)'); ylabel('Magnitude (dB/Hz)');
save_plot(fig, fullfile(plot_dir, 'mat_02_vuv_harmonic_structure.png'));





% compare spectra

[P_noisy_ref, f_n] = welch_psd_onesided(noisy, fs, npsd, overlap_psd, win_psd);
[P_vuv_ref, f_v]   = welch_psd_onesided(vuv,   fs, npsd, overlap_psd, win_psd);

fig = figure('Name', 'Spectrum Comparison');
plot(f_n, 10*log10(P_noisy_ref + 1e-18), 'LineWidth', 0.9); hold on;
plot(f_v, 10*log10(P_vuv_ref + 1e-18), 'LineWidth', 0.9); grid on;
xlim([0 min(2000, fs/2)]);
legend('Noisy Signal', 'Vuvuzela Only', 'Location', 'northeast');
title('Spectrum Comparison (Used for Filter Design)');
xlabel('Frequency (Hz)'); ylabel('Magnitude (dB)');
save_plot(fig, fullfile(plot_dir, 'mat_03_spectrum_design_comparison.png'));




% stft suppression

n_fft = 1024;
hop = 256;
overlap = n_fft - hop;
win = hanning(n_fft, 'periodic');

[Z_noisy, f_stft_n, t_stft_n] = stft_onesided(noisy, fs, n_fft, hop, win);
[Z_vuv, ~, ~] = stft_onesided(vuv, fs, n_fft, hop, win);

S_noisy = abs(Z_noisy).^2;
S_noise = abs(Z_vuv).^2;
noise_psd = mean(S_noise, 2) + 1e-12;
noise_psd_col = noise_psd;




% parameters
alpha = 1.35;
oversub = 1.25;
sub_floor = 0.02;
gain_floor = 0.03;
time_smooth = 0.82;




% Harmonic controls (for balanced buzz suppression without tunneling)
harmonic_depth = 0.95;
harmonic_bw_hz = 56.0;

% Wiener gain
H_wiener = S_noisy ./ (S_noisy + alpha * repmat(noise_psd_col, 1, columns(S_noisy)) + 1e-12);
H_wiener = min(max(H_wiener, gain_floor), 1.0);
H_wiener = median_filter_freq(H_wiener, 7);

% Spectral subtraction gain
S_sub = max(S_noisy - oversub * repmat(noise_psd_col, 1, columns(S_noisy)), ...
            sub_floor * repmat(noise_psd_col, 1, columns(S_noisy)));
H_sub = sqrt(S_sub ./ (S_noisy + 1e-12));

% Temporal smoothing
for n = 2:columns(H_wiener)
  H_wiener(:,n) = time_smooth * H_wiener(:,n-1) + (1 - time_smooth) * H_wiener(:,n);
end




% Harmonic suppression mask with sidebands
F = repmat(f_stft_n, 1, columns(H_wiener));
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
H_tone = repmat(H_tone, 1, columns(H_wiener));

H_total = H_wiener .* H_sub .* harmonic_mask .* H_tone;
H_total = min(max(H_total, 0.03), 1.0);

Z_stage1 = H_total .* Z_noisy;
y_stage1 = istft_onesided(Z_stage1, length(noisy), n_fft, hop, win);






% notch cascade and cleanup

y_notch = y_stage1;

Q = 22.0;  % Increased from 16.0 for sharper harmonic tracking
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
      y_notch = zero_phase_filter(b_notch, a_notch, y_notch);
    end
  end
end





% Speech presence boost (slightly wider band for more natural timbre)
[b_bp, a_bp] = butter(2, [900 3400]/(fs/2), 'bandpass');
speech_band = zero_phase_filter(b_bp, a_bp, y_notch);
y_enh = y_notch + 0.14 * speech_band;



% Less aggressive low-frequency cleanup to reduce hollow/tunnel voice effect
[b_hp, a_hp] = butter(2, 140/(fs/2), 'high');
y_enh = zero_phase_filter(b_hp, a_hp, y_enh);



% Extra-sharp notch on fundamental to eliminate low-mid buzz
if f0 > 40 && f0 < (fs/2 - 40)
  Q_fund = 40.0;  % Very sharp, just for fundamental
  w0_fund = 2*pi*f0/fs;
  r = 1 - (f0/(fs/2)) / (2*Q_fund);
  r = min(max(r, 0.925), 0.9999);
  b_fund = [1, -2*cos(w0_fund), 1];
  a_fund = [1, -2*r*cos(w0_fund), r^2];
  y_enh = zero_phase_filter(b_fund, a_fund, y_enh);
end



% Post-STFT residual de-buzz gate
[Z_post, f_post, ~] = stft_onesided(y_enh, fs, n_fft, hop, win);
P_post = abs(Z_post).^2;
noise_floor_post = percentile_rows(P_post, 20);



post_strength = 3.20;  %residual gating for buzz suppression
H_post = (P_post - post_strength * repmat(noise_floor_post, 1, columns(P_post))) ./ (P_post + 1e-12);
H_post = min(max(H_post, 0.09), 1.0);

F_post = repmat(f_post, 1, columns(H_post));
harm_post = ones(size(H_post));
for k = 1:length(harmonics)
  fh = harmonics(k);
  g = exp(-0.5 * ((F_post - fh) / 56.0).^2);
  harm_post = harm_post .* (1.0 - 0.82 * g);
end
harm_post = min(max(harm_post, 0.07), 1.0);

H_post_total = H_post .* harm_post;
H_post_total = min(max(H_post_total, 0.12), 1.0);



% PSD ceiling above 2 kHz using noisy-track PSD as reference upper bound
noise_psd_interp = interp1(f_n, P_noisy_ref, f_post, 'linear', 'extrap');
noise_psd_interp = max(noise_psd_interp, 1e-18);
ceiling_margin = 1.00;
hf_mask = (f_post >= 2000.0);
H_ceiling = sqrt(min(ones(size(P_post)), ...
                 repmat(ceiling_margin * noise_psd_interp, 1, columns(P_post)) ./ (P_post + 1e-12)));
mask_mat = repmat(hf_mask, 1, columns(P_post));
H_post_total = H_post_total .* ((1 - mask_mat) + mask_mat .* H_ceiling);



% Final narrow correction for 2.2-2.8 kHz region
band_fix = ones(rows(P_post), 1);
idx_fix = (f_post >= 2200.0) & (f_post <= 2800.0);
band_fix(idx_fix) = 0.90;
H_post_total = H_post_total .* repmat(band_fix, 1, columns(P_post));
H_post_total = min(max(H_post_total, 0.05), 1.0);




% Additional high-frequency shelf attenuation to keep 2-4 kHz below noisy floor
hf_start_hz = 2000.0;
hf_end_hz = min(4500.0, fs/2);
hf_tilt = ones(rows(P_post), 1);
if hf_end_hz > hf_start_hz
  idx_hf = (f_post >= hf_start_hz);
  hf_tilt(idx_hf) = interp1([hf_start_hz, hf_end_hz], [0.94, 0.55], f_post(idx_hf), 'linear', 'extrap');
end
H_post_total = H_post_total .* repmat(hf_tilt, 1, columns(P_post));
H_post_total = min(max(H_post_total, 0.10), 1.0);

y_enh = istft_onesided(H_post_total .* Z_post, length(noisy), n_fft, hop, win);



% Final time-domain high-frequency shelf attenuation (moderate to avoid tunneling)
[b_lp, a_lp] = butter(2, 2000/(fs/2), 'low');
y_lp = zero_phase_filter(b_lp, a_lp, y_enh);
y_hf = y_enh - y_lp;
y_enh = y_lp + 0.52 * y_hf;



% Tiny intelligibility lift in the 1.4-2.2 kHz consonant region
[b_mid, a_mid] = butter(2, [1400 2200]/(fs/2), 'bandpass');
mid_band = zero_phase_filter(b_mid, a_mid, y_enh);
y_enh = y_enh + 0.02 * mid_band;



% Guard against single-sample outliers dominating normalization.
abs_y = abs(y_enh);
peak_ref = percentile_vec(abs_y, 99.9);
if peak_ref < 1e-8
  peak_ref = max(abs_y);
end
y_enh = y_enh / (peak_ref + 1e-12);
y_enh = max(min(y_enh, 1.0), -1.0);
y_enh = 0.92 * y_enh;

fprintf('Input RMS:  %.6f\n', rms_local(noisy));
fprintf('Output RMS: %.6f\n', rms_local(y_enh));





% Plotting and utility functions

[P_out, f_out] = welch_psd_onesided(y_enh, fs, npsd, overlap_psd, win_psd);

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



% plot results

fig = figure('Name','Time Result');
subplot(2,1,1);
plot((0:length(noisy)-1)/fs, noisy, 'LineWidth', 0.8); grid on;
title('Noisy Signal'); xlabel('Time (s)'); ylabel('Amplitude');

subplot(2,1,2);
plot((0:length(y_enh)-1)/fs, y_enh, 'LineWidth', 0.8); grid on;
title('Filtered Signal'); xlabel('Time (s)'); ylabel('Amplitude');

save_plot(fig, fullfile(plot_dir, 'mat_04_time_domain_result.png'));

fig = figure('Name','Spectrogram Result');
[S1, f1, t1] = stft_onesided(noisy, fs, n_fft, hop, win);
[S2, f2, t2] = stft_onesided(y_enh, fs, n_fft, hop, win);

subplot(2,1,1);
imagesc(t1, f1, 20*log10(abs(S1)+1e-12)); axis xy; colorbar;
ylim([0 min(5000, fs/2)]); title('Noisy Spectrogram');
xlabel('Time (s)'); ylabel('Frequency (Hz)');

subplot(2,1,2);
imagesc(t2, f2, 20*log10(abs(S2)+1e-12)); axis xy; colorbar;
ylim([0 min(5000, fs/2)]); title('Filtered Spectrogram');
xlabel('Time (s)'); ylabel('Frequency (Hz)');

save_plot(fig, fullfile(plot_dir, 'mat_05_spectrogram_result.png'));

fig = figure('Name','PSD Comparison');
plot(f_n, 10*log10(P_noisy_ref + 1e-18), 'LineWidth', 1.0); hold on;
plot(f_out, 10*log10(P_out + 1e-18), 'LineWidth', 1.0);
for k = 1:length(harmonics)
  plot([harmonics(k) harmonics(k)], [min(10*log10(P_out+1e-18)) max(10*log10(P_noisy_ref+1e-18))], '--k');
end
grid on;
xlim([0 min(4000, fs/2)]);
legend('Noisy PSD', 'Filtered PSD', 'Location', 'northeast');
title('PSD Comparison After Processing');
xlabel('Frequency (Hz)'); ylabel('PSD (dB/Hz)');
save_plot(fig, fullfile(plot_dir, 'mat_06_psd_result.png'));

fig = figure('Name','Adaptive Gain Heatmap');
imagesc(t_stft_n, f_stft_n, H_total); axis xy;
ylim([0 min(5000, fs/2)]);
colorbar; xlabel('Time (s)'); ylabel('Frequency (Hz)');
title('Adaptive Time-Frequency Gain');
save_plot(fig, fullfile(plot_dir, 'mat_07_gain_heatmap.png'));




% plot filter responses

% Create filter response plots showing magnitude and phase
fig = figure('Name','Filter Responses');

% Define example filters for visualization
% 1. Notch at fundamental
Q_example = 22.0;
w0_notch = 2*pi*f0/fs;
r_notch = 1 - (f0/(fs/2)) / (2*Q_example);
r_notch = min(max(r_notch, 0.90), 0.9999);
b_notch = [1, -2*cos(w0_notch), 1];
a_notch = [1, -2*r_notch*cos(w0_notch), r_notch^2];

% 2. Speech bandpass
[b_speech, a_speech] = butter(2, [900 3400]/(fs/2), 'bandpass');

% 3. High-pass
[b_hp, a_hp] = butter(2, 140/(fs/2), 'high');

% 4. Low-pass for shelf
[b_lp, a_lp] = butter(2, 2000/(fs/2), 'low');

w = linspace(0, pi, 8192);

[H_speech, W] = freqz(b_speech, a_speech, w);
[H_hp, ~] = freqz(b_hp, a_hp, w);
[H_lp, ~] = freqz(b_lp, a_lp, w);

f_plot = W * fs / (2*pi);

% Row 1: all notch responses (all harmonics and +/- drift) in one magnitude + one phase plot
subplot(3,2,1);
hold on;
for k = 1:length(harmonics)
  fh = harmonics(k);
  for c = 1:3
    if c == 1
      fc = fh - drift_hz;
      style = '--';
      color = [0.2 0.5 0.9];
      lw = 0.9;
    elseif c == 2
      fc = fh;
      style = '-';
      color = [0.9 0.2 0.2];
      lw = 1.2;
    else
      fc = fh + drift_hz;
      style = '--';
      color = [0.1 0.3 0.7];
      lw = 0.9;
    end

    if fc > 40 && fc < (fs/2 - 40)
      w0_rad_n = 2*pi*fc/fs;
      r_n = 1 - (fc/(fs/2)) / (2*Q);
      r_n = min(max(r_n, 0.90), 0.9999);
      b_n = [1, -2*cos(w0_rad_n), 1];
      a_n = [1, -2*r_n*cos(w0_rad_n), r_n^2];
      Hn = freqz(b_n, a_n, w);
      plot(f_plot, 20*log10(abs(Hn) + 1e-12), style, 'Color', color, 'LineWidth', lw);
    end
  end
end
grid on;
title('All Notch Magnitude Responses (h_k and h_k \pm 12 Hz)');
xlabel('Frequency (Hz)'); ylabel('Magnitude (dB)');
xlim([0 min(2200, fs/2)]);
ylim([-50 3]);
yl_mag = ylim;
for k = 1:length(harmonics)
  plot([harmonics(k) harmonics(k)], yl_mag, ':k', 'LineWidth', 0.7);
end
hold off;

subplot(3,2,2);
hold on;
for k = 1:length(harmonics)
  fh = harmonics(k);
  for c = 1:3
    if c == 1
      fc = fh - drift_hz;
      style = '--';
      color = [0.2 0.5 0.9];
      lw = 0.9;
    elseif c == 2
      fc = fh;
      style = '-';
      color = [0.9 0.2 0.2];
      lw = 1.2;
    else
      fc = fh + drift_hz;
      style = '--';
      color = [0.1 0.3 0.7];
      lw = 0.9;
    end

    if fc > 40 && fc < (fs/2 - 40)
      w0_rad_n = 2*pi*fc/fs;
      r_n = 1 - (fc/(fs/2)) / (2*Q);
      r_n = min(max(r_n, 0.90), 0.9999);
      b_n = [1, -2*cos(w0_rad_n), 1];
      a_n = [1, -2*r_n*cos(w0_rad_n), r_n^2];
      Hn = freqz(b_n, a_n, w);
      plot(f_plot, unwrap(angle(Hn))*180/pi, style, 'Color', color, 'LineWidth', lw);
    end
  end
end
grid on;
title('All Notch Phase Responses (h_k and h_k \pm 12 Hz)');
xlabel('Frequency (Hz)'); ylabel('Phase (deg)');
xlim([0 min(2200, fs/2)]);
yl_phase = ylim;
for k = 1:length(harmonics)
  plot([harmonics(k) harmonics(k)], yl_phase, ':k', 'LineWidth', 0.7);
end
hold off;

% Row 2: speech bandpass magnitude and phase
subplot(3,2,3);
plot(f_plot, 20*log10(abs(H_speech) + 1e-12), 'LineWidth', 1.2); grid on;
title('Speech Bandpass Magnitude (900-3400 Hz)');
xlabel('Frequency (Hz)'); ylabel('Magnitude (dB)');
xlim([0 min(4000, fs/2)]);

subplot(3,2,4);
plot(f_plot, unwrap(angle(H_speech)) * 180/pi, 'LineWidth', 1.2); grid on;
title('Speech Bandpass Phase');
xlabel('Frequency (Hz)'); ylabel('Phase (deg)');
xlim([0 min(4000, fs/2)]);

% Row 3: high-pass and low-pass combined for easier comparison
subplot(3,2,5);
plot(f_plot, 20*log10(abs(H_hp) + 1e-12), 'LineWidth', 1.2); hold on;
plot(f_plot, 20*log10(abs(H_lp) + 1e-12), 'LineWidth', 1.2);
grid on;
title('High-Pass / Low-Pass Magnitude');
xlabel('Frequency (Hz)'); ylabel('Magnitude (dB)');
xlim([0 min(4000, fs/2)]);
legend('High-pass 140 Hz', 'Low-pass 2000 Hz', 'Location', 'southwest');

subplot(3,2,6);
plot(f_plot, unwrap(angle(H_hp)) * 180/pi, 'LineWidth', 1.2); hold on;
plot(f_plot, unwrap(angle(H_lp)) * 180/pi, 'LineWidth', 1.2);
grid on;
title('High-Pass / Low-Pass Phase');
xlabel('Frequency (Hz)'); ylabel('Phase (deg)');
xlim([0 min(4000, fs/2)]);
legend('High-pass 140 Hz', 'Low-pass 2000 Hz', 'Location', 'southwest');

save_plot(fig, fullfile(plot_dir, 'mat_08_filter_responses_mag_phase.png'));

% save outputs

out_path = fullfile(audio_dir, 'final_output_octave.wav');
audiowrite(out_path, y_enh, fs);
fprintf('\nSaved: %s\n', out_path);

summary_path = fullfile(artifacts_dir, 'octave_report_summary.txt');
fid = fopen(summary_path, 'w');
fprintf(fid, 'fs=%d\n', fs);
fprintf(fid, 'f0_estimated_hz=%.6f\n', f0);
fprintf(fid, 'harmonics_hz=%s\n', mat2str(harmonics));
fprintf(fid, 'alpha=%.6f\n', alpha);
fprintf(fid, 'oversub=%.6f\n', oversub);
fprintf(fid, 'gain_floor=%.6f\n', gain_floor);
fprintf(fid, 'harmonic_depth=%.6f\n', harmonic_depth);
fprintf(fid, 'harmonic_bw_hz=%.6f\n', harmonic_bw_hz);
fprintf(fid, 'tone_gate_strength=%.6f\n', tone_gate_strength);
fprintf(fid, 'Q=%.6f\n', Q);
fprintf(fid, 'drift_hz=%.6f\n', drift_hz);
fprintf(fid, 'post_strength=%.6f\n', post_strength);
fprintf(fid, 'speech_band_change_db=%.6f\n', speech_change_db);
fprintf(fid, 'low_band_change_db=%.6f\n', low_change_db);
fprintf(fid, 'harmonic_band_change_db=%.6f\n', harm_change_db);
fclose(fid);

fprintf('Saved summary to %s\n', summary_path);

% play audio

fprintf('\nPlayback: original then filtered...\n');
try
  fprintf('Playing noisy signal...\n');
  soundsc(noisy, fs);
  pause(length(noisy)/fs + 0.5);

  fprintf('Playing filtered signal...\n');
  soundsc(y_enh, fs);
  pause(length(y_enh)/fs + 0.5);
catch
  fprintf('Audio playback failed (device unavailable). Output WAV was still saved.\n');
end

endfunction

% local helpers

function [S, f, t] = stft_onesided(x, fs, n_fft, hop, win)
  x = x(:);
  L = length(x);
  n_frames = 1 + ceil((L - n_fft) / hop);
  if n_frames < 1, n_frames = 1; end
  L_pad = (n_frames-1)*hop + n_fft;
  x_pad = zeros(L_pad, 1);
  x_pad(1:L) = x;

  n_bins = floor(n_fft/2) + 1;
  S = zeros(n_bins, n_frames);

  for m = 1:n_frames
    idx = (m-1)*hop + (1:n_fft);
    frame = x_pad(idx) .* win;
    X = fft(frame, n_fft);
    S(:,m) = X(1:n_bins);
  end

  f = (0:n_bins-1)' * fs / n_fft;
  center = (n_fft/2);
  t = ((0:n_frames-1)*hop + center)' / fs;
  t = t(:)';
end

function y = istft_onesided(S, out_len, n_fft, hop, win)
  n_bins = rows(S);
  n_frames = columns(S);

  if mod(n_fft,2) == 0
    mirror_part = S(n_bins-1:-1:2,:);
  else
    mirror_part = S(n_bins:-1:2,:);
  end

  X_full = [S; conj(mirror_part)];

  L_out = (n_frames-1)*hop + n_fft;
  y_acc = zeros(L_out, 1);
  w_acc = zeros(L_out, 1);

  for m = 1:n_frames
    x_frame = real(ifft(X_full(:,m), n_fft));
    idx = (m-1)*hop + (1:n_fft);
    y_acc(idx) = y_acc(idx) + x_frame .* win;
    w_acc(idx) = w_acc(idx) + (win.^2);
  end

  w_thr = 1e-4 * max(w_acc);
  y = zeros(size(y_acc));
  valid = (w_acc > w_thr);
  y(valid) = y_acc(valid) ./ w_acc(valid);
  y = y(1:out_len);
end

function Y = median_filter_freq(X, k)
  if mod(k,2) == 0, k = k + 1; end
  h = floor(k/2);
  Y = X;
  for c = 1:columns(X)
    for r = 1:rows(X)
      r1 = max(1, r-h);
      r2 = min(rows(X), r+h);
      Y(r,c) = median(X(r1:r2,c));
    end
  end
end

function y = zero_phase_filter(b, a, x)
  % Use filtfilt when available, otherwise forward-backward filtering.
  try
    y = filtfilt(b, a, x);
  catch
    y = filter(b, a, x);
    y = flipud(y);
    y = filter(b, a, y);
    y = flipud(y);
  end
end

function [Pxx, f] = welch_psd_onesided(x, fs, nfft, noverlap, win)
  x = x(:);
  hop = nfft - noverlap;
  if hop <= 0, hop = floor(nfft/2); end

  L = length(x);
  n_frames = 1 + floor((L - nfft) / hop);
  if n_frames < 1
    n_frames = 1;
    x = [x; zeros(nfft - L, 1)];
    L = length(x);
  end

  L_need = (n_frames-1)*hop + nfft;
  if L < L_need
    x = [x; zeros(L_need - L, 1)];
  end

  n_bins = floor(nfft/2) + 1;
  Pxx = zeros(n_bins, 1);
  U = sum(win.^2);

  for m = 1:n_frames
    idx = (m-1)*hop + (1:nfft);
    frame = x(idx) .* win;
    X = fft(frame, nfft);
    X = X(1:n_bins);
    Pxx = Pxx + (abs(X).^2) / (U * fs);
  end

  Pxx = Pxx / n_frames;

  if mod(nfft,2) == 0
    Pxx(2:end-1) = 2 * Pxx(2:end-1);
  else
    Pxx(2:end) = 2 * Pxx(2:end);
  end

  f = (0:n_bins-1)' * fs / nfft;
end

function p = bandpower_psd(Pxx, f, f1, f2)
  idx = (f >= f1) & (f <= f2);
  if ~any(idx)
    p = 0;
    return;
  end
  p = trapz(f(idx), Pxx(idx));
end

function r = rms_local(x)
  r = sqrt(mean(x(:).^2) + 1e-12);
end

function p = percentile_vec(v, pct)
  v = sort(v(:));
  n = length(v);
  if n == 0
    p = 0;
    return;
  end
  pct = min(max(pct, 0), 100);
  pos = 1 + (n-1) * (pct/100);
  lo = floor(pos);
  hi = ceil(pos);
  if lo == hi
    p = v(lo);
  else
    p = v(lo) + (pos-lo) * (v(hi)-v(lo));
  end
end

function q = percentile_rows(X, p)
  p = min(max(p, 0), 100);
  q = zeros(rows(X), 1);
  for r = 1:rows(X)
    v = sort(X(r,:));
    n = length(v);
    pos = 1 + (n-1) * (p/100);
    lo = floor(pos);
    hi = ceil(pos);
    if lo == hi
      q(r) = v(lo);
    else
      q(r) = v(lo) + (pos-lo) * (v(hi)-v(lo));
    end
  end
end

function save_plot(fig, out_path)
  try
    saveas(fig, out_path);
  catch
    print(fig, out_path, '-dpng');
  end
end
