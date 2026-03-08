function [h, nh] = echoIR(D, alpha)
    if ~isscalar(alpha) || alpha <= 0 || alpha >= 1
        error('alpha must be a scalar strictly between 0 and 1.');
    end
    nh = 0:D;
    h = zeros(1, D+1);
    h(1)     = 1;      
    h(end)   = alpha; 
end
