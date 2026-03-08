% read trumpet signal (use first channel if stereo)
[y, Fst] = audioread('trumpet.wav');   
y = y(:,1);                            
fprintf('length(y) = %d samples, Fst = %.1f Hz\n', length(y), Fst);

% choose segment length: 30 ms in samples and trim to full segments
M = round(0.030 * Fst);        
Ny = length(y);
P = floor(Ny / M);
y = y(1:M*P);                  
Ny = length(y);
fprintf('M = %d samples (30 ms), P = %d segments, length(y) = %d\n', M, P, Ny);

% arrange signal into columns, each column is one 30 ms block
yseg = reshape(y, M, P);   
fprintf('yseg is %d-by-%d (M-by-P)\n', size(yseg,1), size(yseg,2));

% Fourier coefficients of each block (DTFS per segment)
Yseg = fft(yseg, [], 1);   
fprintf('Yseg has same size as yseg: %d-by-%d\n', size(Yseg,1), size(Yseg,2));

% global maximum magnitude across all coefficients
maxval = max(abs(Yseg), [], 'all');
fprintf('maxval = %.4e\n', maxval);

% keep only coefficients above fixed fraction of maxval
threshold = 0.01;   
Ysegtrunc = Yseg .* (abs(Yseg) > threshold*maxval);
fprintf('applied threshold = %.4f * maxval\n', threshold);

% store truncated coefficients in sparse form to save memory
Ysegtrunc_sparse = sparse(Ysegtrunc);
info_y           = whos('y');
info_Ysegtrunc_s = whos('Ysegtrunc_sparse');
fprintf('Task 7:\n');
fprintf('  y uses                %.1f kB of memory\n', info_y.bytes/1024);
fprintf('  Ysegtrunc_sparse uses %.1f kB of memory\n', info_Ysegtrunc_s.bytes/1024);

% reconstruct segments from truncated coefficients
Ysegtrunc_full = full(Ysegtrunc_sparse);
yseg_trunc = ifft(Ysegtrunc_full, [], 1);

% stitch blocks back into a single time-domain signal
ytrunc = reshape(yseg_trunc, M*P, 1);

% listen to original vs compressed / reconstructed signal
soundsc(y, Fst);      
soundsc(ytrunc, Fst); 


%% compare waveforms across a segment boundary (Task 8d)

p = 5;                        % choose a segment index to inspect
n_start = (p-1)*M + 1;
n_end   = (p+1)*M;            % cover two neighbouring segments
n_range = n_start:n_end;

t = (n_range-1)/Fst;          

figure;
plot(t, y(n_range), 'b', 'LineWidth', 1.0); hold on;
plot(t, real(ytrunc(n_range)), 'r--', 'LineWidth', 1.0);
xlabel('Time [s]');
ylabel('Amplitude');
title('Original y vs truncated y_{trunc} across a segment boundary');
legend('y (original)', 'y_{trunc} (reconstructed)');
grid on;
