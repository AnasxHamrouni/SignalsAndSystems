function [y, ny] = myconv(x, nx, h, nh)
    ax = nx(1);
    bx = nx(end);
    ah = nh(1);
    bh = nh(end);

    ay = ax + ah;
    by = bx + bh;
    ny = ay:by;

    Lx = length(x);
    Lh = length(h);
    Ly = Lx + Lh - 1;

    y = zeros(1, Ly);
    for n = 1:Ly
        for k = 1:Lx
            m = n - k + 1;
            if m >= 1 && m <= Lh
                y(n) = y(n) + x(k) * h(m);
            end
        end
    end
end

