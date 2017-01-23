function [] = killRinging(s,~,~)

% V = s.filtered_voltage;
% Fs = s.pref.deltat; 

% % FFT it
% T = 1/Fs;
% L = length(V);
% NFFT = 2^nextpow2(L);

% Y = fft(V,NFFT)/L;
% f = Fs/2*[linspace(0,1,NFFT/2) linspace(1,0,NFFT/2)]; 

% % now, cut out the maximum freqyency
% [~,idx] = max(abs(Y));
% peak_freq = f(idx);
% notch_min = floor(peak_freq) - .5;
% notch_max = ceil(peak_freq) + .5;
% a = find(f>notch_min,1,'first');
% z = find(f>notch_max,1,'first');
% Y(a:z) = 0;

% a = find(f>notch_max,1,'last');
% z = find(f>notch_min,1,'last');
% Y(a:z) = 0;

% % inverse transform it
% yhat = ifft(Y);

% % cut it 
% yhat = length(V)*yhat(1:length(V));

% s.filtered_voltage = real(yhat);