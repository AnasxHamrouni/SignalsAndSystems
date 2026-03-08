load echart;
imshow(echart);

[p, q] = size(echart)

echartnoisy = echart + 0.8*rand(size(echart));
imshow(echartnoisy);
imshow(echartnoisy,[]);