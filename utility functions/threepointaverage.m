function [y, ny] = threepointaverage(x, nx)
% [y, ny] = threepointaverage(x, nx)
% x, nx : input signal and its time indices (row vectors, same length)
% y, ny : output signal and its time indices (same as nx)

if length(x) ~= length(nx)
    error('x and nx must have the same length');
end

[x1, n1] = gainsys(1/3, x, nx);

[x2d, n2d] = delaysys(1, x, nx);      
[x2, n2]   = gainsys(1/3, x2d, n2d);

[x3d, n3d] = delaysys(2, x, nx);    
[x3, n3]   = gainsys(1/3, x3d, n3d);

[u, nu] = sumsys(x1, n1, x2, n2);
[y, ny] = sumsys(u, nu, x3, n3);
