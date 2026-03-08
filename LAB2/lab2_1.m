[x, nx] = dtimpulse(0, 0, 0);

h  = [1:1:3, 3:-1:1];
nh = -2:3;

[y, ny] = myconv(x, nx, h, nh)
[y, ny] = myconv( h, nh, x, nx)

x  = [1 1 1];
nx = 2:4;

[y1, ny1] = myconv(x,nx,h,nh)
[y2, ny2] = myconv(h,nh,x,nx)

