Fs = 256;
load('ECG.mat');
x = ECG(:);
N = length(x);

% Low-pass design: keep ≤ 40 Hz
fc_Hz = 40;
wc    = 2*pi*fc_Hz/Fs;      % rad/sample
fc    = wc/pi;              % normalized (fraction of pi)

delta = 0.02;               % small transition width (normalized)

% [0, fc-delta] pass, [fc+delta, 1] stop
Flp = [0         fc-delta   fc+delta   1];
Alp = [1         1          0          0];

L = [50 100 200];
h_lp = cell(1,3);
y_lp = cell(1,3);

for k = 1:3
    h_lp{k} = firpm(L(k)-1, Flp, Alp);   % low-pass filter
    y_lp{k} = conv(x, h_lp{k}, 'full');  % filtered signal
end

f = (-floor(N/2):(N-1-floor(N/2)))*(Fs/N);
X = fft(x);

for k = 1:3
    Y = fft(y_lp{k}, N);

    % (b) Frequency domain
    figure;
    plot(f, fftshift(abs(X))); hold on;
    plot(f, fftshift(abs(Y)));
    xlabel('Frequency (Hz)');
    ylabel('Magnitude');
    legend('Original','Low-pass filtered');
    title(sprintf('Low-pass, freq domain, L=%d', L(k)));

    % (d) Time domain 
    t  = (0:N-1)/Fs;
    ty = (0:length(y_lp{k})-1)/Fs;
    tmax = 4;

    figure;
    plot(t(t<=tmax), x(t<=tmax)); hold on;
    plot(ty(ty<=tmax), y_lp{k}(ty<=tmax));
    xlabel('Time (s)');
    ylabel('Amplitude');
    legend('Original','Low-pass filtered');
    title(sprintf('Low-pass, time domain, L=%d', L(k)));
end
