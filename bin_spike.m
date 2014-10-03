function [time_spk, firing_rate] = bin_spike(data,bin_time_wind,samp_rate,tvec)
%   [time_spk, firing_rate] = bin_spike(data,bin_time_wind,samp_rate)
% function [time_spk, firing_rate] = bin_spike(data,bin_time_wind,samp_rate)
%   This function bins spikes given as data with a sliding window size
%   bin_time_wind and sampling rate samp_rate
del_t = 1/samp_rate*1000;    %msec
if mod(fix(bin_time_wind/del_t),2)==0
    boxlen = fix(bin_time_wind/del_t)+1;
else
    boxlen = fix(bin_time_wind/del_t);
end
midp = (boxlen-1)/2;
firing_rate= zeros(length(data)-2*midp,1);
for i = midp+1:length(data)-midp
    firing_rate(i-midp) = sum(data(i-midp:i+midp))/boxlen;
end
time_spk = tvec(midp+1:length(data)-midp);
plot(time_spk,firing_rate)
    