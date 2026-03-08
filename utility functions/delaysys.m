function [y, ny] = delaysys(N, x, nx)
% delaysys: implements delay system y[n] = x[n-N]
% [y, ny] = delaysys(N, x, nx)
% N  : non-negative integer delay
% x  : row vector of samples
% nx : row vector of time indices, same length as x
% y, ny : delayed output signal and its time indices (ny = nx).
%
% Assumes x[n] = 0 for times outside nx.

% basic checks
if length(x) ~= length(nx)
    error('arguments 2 and 3 should have the same length');
end
if ~isscalar(N) || N < 0 || floor(N) ~= N
    error('argument 1 should be a non-negative integer');
end

ny = nx;                  % output time indices unchanged
y  = zeros(size(x));      % start with all zeros

for k = 1:length(nx)
    n = nx(k);            % this output time
    m = n - N;            % corresponding input time index
    idx = find(nx == m, 1);
    if ~isempty(idx)
        y(k) = x(idx);
    else
        y(k) = 0;         % outside range → assume zero
    end
end
