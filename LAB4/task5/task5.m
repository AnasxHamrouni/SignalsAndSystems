Fs = 256;
load('ECG.mat');
x = ECG(:);
N = length(x);


% notch at 50 Hz
fPL = 50;
wPL = 2*pi*fPL/Fs;
fc_notch = wPL/pi;

bands_notch   = [0  fc_notch-0.02  fc_notch-0.01  fc_notch+0.01  fc_notch+0.02  1];
desired_notch = [1  1              0              0              1              1];
L_notch = 20;  % chosen length
h_notch = firpm(L_notch-1, bands_notch, desired_notch);

% High-pass: remove < 1 Hz
fc_hp_Hz = 1;
wc_hp    = 2*pi*fc_hp_Hz/Fs;
fc_hp    = wc_hp/pi;
delta_hp = 0.005;
Fhp = [0  fc_hp-delta_hp  fc_hp+delta_hp  1];
Ahp = [0  0               1               1];
L_hp = 200;
h_hp = firpm(L_hp-1, Fhp, Ahp);

% Low-pass: remove > 40 Hz 
fc_lp_Hz = 40;
wc_lp    = 2*pi*fc_lp_Hz/Fs;
fc_lp    = wc_lp/pi;
delta_lp = 0.02;
Flp = [0  fc_lp-delta_lp  fc_lp+delta_lp  1];
Alp = [1  1               0               0];
L_lp = 100;
h_lp = firpm(L_lp-1, Flp, Alp);

%% 1) Apply the three filters in series

y1 = conv(x, h_notch, 'full');   % remove 50 Hz
y2 = conv(y1, h_hp,    'full');  % remove baseline wander
y3 = conv(y2, h_lp,    'full');  % remove high-freq noise
y  = y3;                         % final filtered ECG

%% 2–4) Find R-peaks and plot

t  = (0:length(y)-1)/Fs;

% Rough automatic threshold: fraction of max
[pks_all, locs_all] = findpeaks(y, 'MinPeakDistance', round(0.3*Fs));  % avoid double peaks
th = 0.5*max(pks_all);   % adjust by hand if needed

% 3) Keep only peaks above threshold (R-peaks)
is_R   = pks_all > th;
R_pks  = pks_all(is_R);
R_loc  = locs_all(is_R);
R_time = R_loc / Fs;

% 4) Plot short segment with R-peaks marked
tmin = 2; tmax = 8;   % choose a segment that shows a few beats
seg_idx = (t >= tmin) & (t <= tmax);
seg_R   = (R_time >= tmin) & (R_time <= tmax);

figure;
plot(t(seg_idx), y(seg_idx)); hold on;
plot(R_time(seg_R), R_pks(seg_R), 'ro', 'MarkerSize', 6, 'LineWidth', 1.5);
xlabel('Time (s)');
ylabel('Amplitude');
title('Filtered ECG with detected R-peaks');
legend('Filtered ECG','R-peaks');

%% 5) RR intervals (samples and seconds)

RR_samples = diff(R_loc);       % in samples
RR_seconds = RR_samples / Fs;   % in seconds

%% 6) Average heart rate

mean_RR_sec = mean(RR_seconds);
HR_bpm = 60 / mean_RR_sec;      % beats per minute

fprintf('Average heart rate ≈ %.1f bpm\n', HR_bpm);
