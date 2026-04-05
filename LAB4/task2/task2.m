Fs  = 256;
fPL = 50;
wPL = 2*pi*fPL/Fs;

load('/MATLAB Drive/lab4/ECG.mat');
x = ECG(:);
N = length(x);

fc = wPL/pi;   % = 1.23/pi

% 3 different notch widths around fc
bands1   = [0      fc-0.02  fc-0.01  fc+0.01  fc+0.02  1];
desired1 = [1      1        0        0        1        1];

bands2   = [0      fc-0.03  fc-0.01  fc+0.01  fc+0.03  1];
desired2 = [1      1        0        0        1        1];

bands3   = [0      fc-0.04  fc-0.01  fc+0.01  fc+0.04  1];
desired3 = [1      1        0        0        1        1];

L  = [5 10 20];
h = cell(3,3);

for iLen = 1:numel(L)
    nTaps = L(iLen);
    h{iLen,1} = firpm(nTaps-1, bands1, desired1);
    h{iLen,2} = firpm(nTaps-1, bands2, desired2);
    h{iLen,3} = firpm(nTaps-1, bands3, desired3);
end

f = (-floor(N/2):(N-1-floor(N/2)))*(Fs/N);

for iLen = 1:3
    for iB = 1:3
        hi = h{iLen,iB};          % now always a vector
        y  = conv(x, hi, 'full');

        X = fft(x);
        Y = fft(y, N);

        figure;
        plot(f, fftshift(abs(X))), hold on;
        plot(f, fftshift(abs(Y)));
        xlabel('Frequency (Hz)');
        ylabel('Magnitude');
        legend('Original','Filtered');
        title(sprintf('Freq domain: L=%d, bandset=%d', L(iLen), iB));

        t  = (0:N-1)/Fs;
        ty = (0:length(y)-1)/Fs;
        tmax = 4;

        idxX = t <= tmax;
        idxY = ty <= tmax;

        figure;
        plot(t(idxX), x(idxX)), hold on;
        plot(ty(idxY), y(idxY));
        xlabel('Time (s)');
        ylabel('Amplitude');
        legend('Original','Filtered');
        title(sprintf('Time domain: L=%d, bandset=%d', L(iLen), iB));

        delay_samples = (L(iLen)-1)/2;
        delay_seconds = delay_samples / Fs;
        fprintf('L=%d, bandset=%d: delay ≈ %.1f samples (%.4f s)\n', ...
                L(iLen), iB, delay_samples, delay_seconds);
    end
end
