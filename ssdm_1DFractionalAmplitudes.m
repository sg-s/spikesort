% ssdm_1DFractionalAmplitudes.m
% 
% this is a plugin for spikesort.m
% reduces spikes to a amplitude, measured from the minimum to preceding maximum.
% part of the spikesort package
% https://github.com/sg-s/spikesort
% created by Srinivas Gorur-Shandilya at 10:20 , 09 April 2014. Contact me at http://srinivas.gs/contact/
% 
% This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. 
% To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
function R = ssdm_1DFractionalAmplitudes(V,Vf,deltat,loc)

wb = waitbar(0.2,'Computing Fractional amplitudes...');

h = (40*1e-4)/deltat; % deltat in seconds
% 1D - find total spike amplitude for each
R = zeros*loc;
loc_max = 0*loc;
[R(1),loc_max(1)] = max(V(loc(1)-h:loc(1)) - V(loc(1)));
for i = 2:length(loc)
	before = max([loc(i)-h loc(i-1)]);
    [R(i),loc_max(i)] = max(V(loc(i)-before:loc(i)) - V(loc(i)));
end
loc_max = loc + loc_max - h; % stores the location of the preceding maximum of each spike

% figure, hold on
time = deltat:deltat:(deltat*length(V));
% plot(time,V)
% scatter(time(loc_max),V(loc_max))

waitbar(0.4,wb,'Building spike envelopes...');
% build an upper and lower envelope

upper_envelope = interp1(time(loc_max),V(loc_max),time);
upper_envelope(1:find(~isnan(upper_envelope),1,'first')) = upper_envelope(find(~isnan(upper_envelope),1,'first'));
upper_envelope((find(~isnan(upper_envelope),1,'last')):end) = upper_envelope(find(~isnan(upper_envelope),1,'last')-1);
lower_envelope = interp1(time(loc),V(loc),time);
lower_envelope(1:find(~isnan(lower_envelope),1,'first')) = lower_envelope(find(~isnan(lower_envelope),1,'first'));
lower_envelope((find(~isnan(lower_envelope),1,'last')):end) = lower_envelope(find(~isnan(lower_envelope),1,'last')-1);


waitbar(0.6,wb,'Estimating spike density...');
% build a time-varying estimate of ISI
t_prev_spike = [0 diff(loc)];
t_next_spike = [diff(loc) 0];
t_closest_spike = (t_next_spike + t_prev_spike)/2;
t_closest_spike(1) = t_next_spike(1);
t_closest_spike(end) = t_prev_spike(end);
isi = interp1(time(loc),t_closest_spike,time);
isi(1:find(~isnan(isi),1,'first')) = isi(find(~isnan(isi),1,'first'));
isi((find(~isnan(isi),1,'last')):end) = isi(find(~isnan(isi),1,'last')-1);
isi = filtfilt(ones(1,h)/h,1,isi); clear t_closest_spike t_prev_spike t_next_spike
% figure, hold on
% plot(time,isi)

waitbar(0.8,wb,'Filtering...');
% filter the envelopes in a time-dependant manner
upper_envelope2 = upper_envelope;
lower_envelope2 = lower_envelope;
scaling_factor = 5;
for i = loc
	before = floor(max([1 i-isi(i)*scaling_factor]));
	after = floor(min([length(isi) i+isi(i)*scaling_factor]));
	upper_envelope2(i) = max(upper_envelope(before:after));
	lower_envelope2(i) = min(lower_envelope(before:after));

end
clear upper_envelope lower_envelope
envelope_amplitude = upper_envelope2- lower_envelope2;

R = R./envelope_amplitude(loc);
close(wb)

