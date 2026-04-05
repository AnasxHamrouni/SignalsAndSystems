Fs = 256;
load('/MATLAB Drive/lab4/ECG.mat');
x = ECG(:);
N = length(x);

fc_Hz = 1;                         % cut-off
wc    = 2*pi*fc_Hz/Fs;             % rad/sample
fc    = wc/pi;                     % normalized

% 2-band high-pass
% [0, fc-δ] stop, [fc+δ, 1] pass, with small transition band
delta = 0.005;                     % transition width (normalized)

Fhp = [0      fc-delta   fc+delta   1];
Ahp = [0      0          1          1];

L = [100 200 500];
h_hp = cell(1,3);
y_hp = cell(1,3);

for k = 1:3
    h_hp{k} = firpm(L(k)-1, Fhp, Ahp);   % high-pass impulse response
    y_hp{k} = conv(x, h_hp{k}, 'full');  % filtered signals
end

f = (-floor(N/2):(N-1-floor(N/2)))*(Fs/N);
X = fft(x);

for k = 1:3
    Y = fft(y_hp{k}, N);

    % Frequency domain
    figure;
    plot(f, fftshift(abs(X))); hold on;
    plot(f, fftshift(abs(Y)));
    xlabel('Frequency (Hz)');
    ylabel('Magnitude');
    legend('Original','High-pass filtered');
    title(sprintf('Freq domain, L=%d', L(k)));

    % Time domain 
    t  = (0:N-1)/Fs;
    ty = (0:length(y_hp{k})-1)/Fs;
    tmax = 4;

    figure;
    plot(t(t<=tmax), x(t<=tmax)); hold on;
    plot(ty(ty<=tmax), y_hp{k}(ty<=tmax));
    xlabel('Time (s)');
    ylabel('Amplitude');
    legend('Original','High-pass filtered');
    title(sprintf('Time domain, L=%d', L(k)));
end
