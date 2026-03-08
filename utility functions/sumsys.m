function [y, nout] = sumsys(x1, nin1, x2, nin2)
% sumsys: implements sum system
% [y, nout] = sumsys(x1, nin1, x2, nin2)
% where x1, x2 are row vectors and nin1, nin2 are their time indices
% (same length and identical entries), produces y[n] = x1[n] + x2[n]
% for all n, and returns the common time index vector nout.

% Check lengths match
if length(x1) ~= length(nin1) || length(x2) ~= length(nin2)
    error('Signal and time vectors must have the same length for each input');
end

if any(nin1 ~= nin2)
    error('Time index vectors nin1 and nin2 must be identical');
end

nout = nin1;
y = x1 + x2;
