Fs  = 160;         
Ts  = 1/Fs;                
n   = (0:79).';      

% sampled cosine x_s[n] = cos(4π n / 160)
xs  = cos(4*pi*(n*Ts));    

% simple unit step implementation
u   = @(n) double(n >= 0);

% finite-length window: keep samples 0..79, zero elsewhere
z   = xs .* (u(n) - u(n-80));

figure;
stem(n, z, 'filled');
xlabel('n');
ylabel('z[n]');
title('z[n] for 0 \leq n \leq 79');
grid on;


% ---- periodic extension of z[n] with period 80 ----
N_z  = 80;                 
n2   = (0:159).';          

% map indices 0..159 into one period 0..79
idx_mod = mod(n2, N_z) + 1;    
z_periodic = z(idx_mod);

figure;
stem(n2, z_periodic, 'filled');
xlabel('n');
ylabel('z_{periodic}[n]');
title('z_{periodic}[n] for 0 \leq n \leq 159');
grid on;


% ---- DTFS of z_periodic via FFT over one period ----
Xz = (1/N_z) * fft(z_periodic(1:N_z)); 

% frequency indices centered at zero
k = -floor(N_z/2):(N_z-1-floor(N_z/2));

figure;
stem(k, fftshift(abs(Xz)), 'filled');
xlabel('k');
ylabel('|Z[k]|');
title('DTFS magnitude of z_{periodic}[n]');
grid on;


% ---- construct w[n] on a shorter window 0..69 ----
n_w = (0:69).';      
xs_w = cos(4*pi*(n_w*Ts));

% same cosine, different window length (70 samples)
w = xs_w .* (u(n_w) - u(n_w-70));   

figure;
stem(n_w, w, 'filled');
xlabel('n');
ylabel('w[n]');
title('w[n] for 0 \leq n \leq 69');
grid on;


% ---- periodic extension of w[n] with period 70 ----
N_w  = 70;                 
n5   = (0:139).';       

% map indices 0..139 into one period 0..69
idx_mod_w = mod(n5, N_w) + 1;
w_periodic = w(idx_mod_w);

figure;
stem(n5, w_periodic, 'filled');
xlabel('n');
ylabel('w_{periodic}[n]');
title('w_{periodic}[n] for 0 \leq n \leq 139');
grid on;


% ---- DTFS of w_periodic via FFT over one period ----
Xw = (1/N_w) * fft(w_periodic(1:N_w));

k_w = -floor(N_w/2):(N_w-1-floor(N_w/2));

figure;
stem(k_w, fftshift(abs(Xw)), 'filled');
xlabel('k');
ylabel('|W[k]|');
title('DTFS magnitude of w_{periodic}[n]');
grid on;
