load echart;
echartnoisy = echart + 0.8*rand(size(echart));

h = [-1 1];

Yrow  = conv2(1, h, echart);
Ycol  = conv2(h', 1, echart);

Yboth = conv2(h', 1, conv2(1, h, echart));

%figure;
%imshow(echart);

figure;
imshow(abs(Yrow),  []); 
title('Edges from image (rows only)');

figure;
imshow(abs(Ycol),  []);  
title('Edges from image (columns only)');

figure;
imshow(abs(Yboth), []); 
title('Edges from image (rows and columns)');


Zrow = conv2(1, h, echartnoisy);
figure;
imshow(abs(Zrow), []);
title('Edges from noisy image (rows only)'); 

sigma1 = 1;
sigma2 = 2;
sigma3 = 3;

n1 = -3*sigma1 : 3*sigma1;
n2 = -3*sigma2 : 3*sigma2;
n3 = -3*sigma3 : 3*sigma3;

h1 = (1/(sqrt(2*pi)*sigma1)) * exp(-n1.^2./(2*sigma1^2));
h2 = (1/(sqrt(2*pi)*sigma2)) * exp(-n2.^2./(2*sigma2^2));
h3 = (1/(sqrt(2*pi)*sigma3)) * exp(-n3.^2./(2*sigma3^2));

figure;
subplot(3,1,1); stem(n1, h1); title('h_1, \sigma = 1');
subplot(3,1,2); stem(n2, h2); title('h_2, \sigma = 2');
subplot(3,1,3); stem(n3, h3); title('h_3, \sigma = 3');

Zblur1 = conv2(h1, h1, echartnoisy);
Zblur2 = conv2(h2, h2, echartnoisy);
Zblur3 = conv2(h3, h3, echartnoisy);

figure;
subplot(1,3,1); imshow(Zblur1,[]); title('Blurred, \sigma = 1');
subplot(1,3,2); imshow(Zblur2,[]); title('Blurred, \sigma = 2');
subplot(1,3,3); imshow(Zblur3,[]); title('Blurred, \sigma = 3');

Zedge1 = conv2(1, h, Zblur1);  
Zedge2 = conv2(1, h, Zblur2);
Zedge3 = conv2(1, h, Zblur3);

figure;
subplot(1,3,1); imshow(abs(Zedge1),[]); title('Edges after blur, \sigma = 1');
subplot(1,3,2); imshow(abs(Zedge2),[]); title('Edges after blur, \sigma = 2');
subplot(1,3,3); imshow(abs(Zedge3),[]); title('Edges after blur, \sigma = 3');

