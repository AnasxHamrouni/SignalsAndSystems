load('dtmfclean.mat');  

Fs = 8192;               
N  = length(xdtmf1);     
Ts = 1/Fs;
n  = (0:N-1).';          
t  = n*Ts;               

% cell array for looping over all clean DTMF signals
signals = {xdtmf1, xdtmf2, xdtmf3, xdtmf4, xdtmf7, xdtmfa};
names   = {'xdtmf1','xdtmf2','xdtmf3','xdtmf4','xdtmf7','xdtmfa'};

% relative threshold for "large" FFT coefficients
large_factor = 0.3;

for i = 1:numel(signals)
    x = signals{i};
    sname = names{i};

    % listen to current clean DTMF tone
    fprintf('Playing %s ...\n', sname);
    soundsc(x, Fs);
    pause(1.2);  

    % DTFS via FFT and magnitude spectrum
    X = fft(x);                       
    magX = abs(X);

    % frequency indices centered at zero
    k = -floor(N/2):(N-1-floor(N/2));  

    figure;
    stem(k, fftshift(magX), 'filled');
    xlabel('k');
    ylabel(['|X_{', sname, '}[k]|']);
    title(['Magnitude spectrum of ', sname, ' (centered)']);
    grid on;

    % find indices whose magnitude is above chosen fraction of max
    maxval = max(magX);
    idx_large = find(magX > large_factor*maxval);  

    fprintf('%s: large-magnitude coefficient indices (0-based):\n', sname);
    disp(idx_large.' - 1);   

    % store 0-based indices for later frequency calculation
    large_idx_struct.(sname) = idx_large - 1;  
end


% ---- Task 3: extract row/column frequencies from dominant bins ----

% manually collected dominant indices (0-based) for each clean signal
k_xdtmf1 = [697 1209 6983 7495];
k_xdtmf2 = [697 1336 6856 7495];
k_xdtmf3 = [697 1477 6715 7495];
k_xdtmf4 = [770 1209 6983 7422];
k_xdtmf7 = [852 1209 6983 7340];
k_xdtmfa = [941 1209 6983 7251];

all_k = [k_xdtmf1;
         k_xdtmf2;
         k_xdtmf3;
         k_xdtmf4;
         k_xdtmf7;
         k_xdtmfa];

% keep only baseband copies (0..N/2) – actual physical tones
base_k = all_k(all_k <= N/2);   

% distinct tone frequencies in Hz (Fs = N = 8192 => f = k)
f_candidates = unique(base_k);  

disp('All distinct tone frequencies in Hz (from one period):');
disp(f_candidates.');

% split into row and column sets according to their values
row_freqs_Hz    = [697 770 852 941];
col_freqs_Hz    = [1209 1336 1477];

% corresponding discrete-time radian frequencies ω = 2πf/Fs
row_omegas_rad  = 2*pi*row_freqs_Hz/Fs;   
col_omegas_rad  = 2*pi*col_freqs_Hz/Fs;   

fprintf('Row frequencies (Hz):    '); disp(row_freqs_Hz);
fprintf('Column frequencies (Hz): '); disp(col_freqs_Hz);
fprintf('Row ω_ri (radians):\n');
disp(row_omegas_rad.');
fprintf('Column ω_cj (radians):\n');
disp(col_omegas_rad.');


% ---- Task 4–7: analyse noisy DTMF signal ----

load('dtmfnoisy.mat');   

N_y = length(ydtmf);    
duration_y = N_y / Fs;   % duration in seconds
fprintf('ydtmf length = %d samples, duration ≈ %.4f s\n', N_y, duration_y);

% listen to noisy tone
soundsc(ydtmf, Fs);

% FFT and magnitude spectrum of noisy signal
Xy    = fft(ydtmf);
magXy = abs(Xy);

N_y   = length(ydtmf);
k_y   = -floor(N_y/2):(N_y-1-floor(N_y/2));

figure;
stem(k_y, fftshift(magXy), 'filled');
xlabel('k');
ylabel('|Y[k]|');
title('Magnitude spectrum of ydtmf (centered)');
grid on;

% detect large-magnitude bins in noisy spectrum
maxval_y   = max(magXy);
large_facY = 0.3;               
idx_large_y = find(magXy > large_facY*maxval_y);

fprintf('ydtmf large-magnitude coefficient indices (0-based):\n');
disp(idx_large_y.' - 1);         

% print approximate frequencies for those bins
for k0 = (idx_large_y.' - 1)
    f = k0*Fs/N_y;
    fprintf('k = %d -> f ≈ %.1f Hz\n', k0, f);
end
