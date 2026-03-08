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

