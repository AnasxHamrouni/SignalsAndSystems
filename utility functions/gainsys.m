function [y, ty] = gainsys(K, x, tx)
% gainsys: implements gain system
% [y, ty] = gainsys(K, x, tx)
% where x and tx are row vectors of the same length, and K is a scalar,
% produces signal y obtained by scaling x by K and having the same time indices.

if length(x) ~= length(tx)
    error('arguments 2 and 3 should have the same length');
end

if ~isscalar(K)
    error('argument 1 should be a scalar');
end

ty = tx;
y  = K .* x;
