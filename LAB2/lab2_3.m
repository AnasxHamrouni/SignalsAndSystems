[trumpet_y, trumpet_Fs] = audioread('trumpet.wav');
soundsc(trumpet_y, trumpet_Fs);

L_trumpet = length(trumpet_y) 

[hSports, Fs_sports] = audioread('sportscentre.wav');

Fs_sports, trumpet_Fs

trumpetSports = conv(trumpet_y, hSports);
save('trumpetSports.mat','trumpetSports');

soundsc(trumpetSports, trumpet_Fs);

N_trumpet = length(trumpet_y);
N_trumpetSports = length(trumpetSports);
t_trumpet = (0:N_trumpet-1)/trumpet_Fs;
t_trumpetSports = (0:N_trumpetSports-1)/trumpet_Fs;

figure;
subplot(2,1,1);
plot(t_trumpet, trumpet_y);
xlabel('Time (s)');
ylabel('Amplitude');
title('Original trumpet (anechoic)');
xlim([0, t_trumpet(end)]); 

subplot(2,1,2);
plot(t_trumpetSports, trumpetSports);
xlabel('Time (s)');
ylabel('Amplitude');
title('Trumpet in sports centre');
xlim([0, t_trumpet(end)]);   

[hCave, Fs_cave] = audioread('cavemono.wav'); 
Fs_cave, trumpet_Fs
trumpetCave = conv(trumpet_y, hCave);
soundsc(trumpetCave, trumpet_Fs); 


N_trumpetCave = length(trumpetCave);
t_trumpetCave = (0:N_trumpetCave-1)/trumpet_Fs;

figure;
subplot(2,1,1);
plot(t_trumpet, trumpet_y);
xlabel('Time (s)');
ylabel('Amplitude');
title('Original trumpet (anechoic)');
xlim([0, t_trumpet(end)]);   

subplot(2,1,2);
plot(t_trumpetCave, trumpetCave);
xlabel('Time (s)');
ylabel('Amplitude');
title('Trumpet in cave');
xlim([0, t_trumpet(end)]);