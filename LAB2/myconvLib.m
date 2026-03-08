function [y, ny] = myconvLib(x, nx, h, nh)

    ax = nx(1);
    bx = nx(end);
    ah = nh(1);
    bh = nh(end);

    ay = ax + ah;
    by = bx + bh;
    ny = ay:by;

    y = conv(x, h);
end

