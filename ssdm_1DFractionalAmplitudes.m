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
function R = ssdm_1DFractionalAmplitudes(V,Vf,deltat,loc,ax,ax2)

wb = waitbar(0.2,'Computing Fractional amplitudes...');

h = (40*1e-4)/deltat; % deltat in seconds
% 1D - find total spike amplitude for each
R = zeros*loc;
loc_max = 0*loc;
[R(1),loc_max(1)] = max(V(loc(1)-h:loc(1)) - V(loc(1)));
loc_max(1) = loc(1) + loc_max(1) - h;
for i = 2:length(loc)
	if get(flip_V_control,'Value')
		before = max([loc(i)-h loc(i-1)]);
		[R(i),loc_max(i)] = max(V(before:loc(i)) - V(loc(i)));
		loc_max(i) = loc_max(i) + before;
	else
		after = min([length(V) loc(i)+h]);
		[R(i),loc_max(i)] =  max(V(loc(i)) - V(loc(i):after));
	end
end


time = deltat:deltat:(deltat*length(V));
% figure, hold on
% plot(time,V)
% scatter(time(loc),V(loc))
% scatter(time(loc_max),V(loc_max))



waitbar(0.4,wb,'Building spike envelopes...');
% build an upper and lower envelope

upper_envelope = interp1(time(loc_max),V(loc_max),time);
upper_envelope(1:find(~isnan(upper_envelope),1,'first')) = upper_envelope(find(~isnan(upper_envelope),1,'first'));
upper_envelope((find(~isnan(upper_envelope),1,'last')):end) = upper_envelope(find(~isnan(upper_envelope),1,'last')-1);
lower_envelope = interp1(time(loc),V(loc),time);
lower_envelope(1:find(~isnan(lower_envelope),1,'first')) = lower_envelope(find(~isnan(lower_envelope),1,'first'));
lower_envelope((find(~isnan(lower_envelope),1,'last')):end) = lower_envelope(find(~isnan(lower_envelope),1,'last')-1);
% plot(ax,time,lower_envelope,'g')
% plot(ax,time,upper_envelope,'r')

waitbar(0.6,wb,'Estimating spike density...');
% build a time-varying estimate of ISI
t_prev_spike = [0 diff(loc)];
t_next_spike = [diff(loc) 0];
t_closest_spike = (t_next_spike + t_prev_spike)/2;
t_closest_spike(1) = t_next_spike(1);
t_closest_spike(end) = t_prev_spike(end);
mean_isi = mean(t_closest_spike); std_isi = std(t_closest_spike);
isi = interp1(time(loc),t_closest_spike,time);
isi(1:find(~isnan(isi),1,'first')) = isi(find(~isnan(isi),1,'first'));
isi((find(~isnan(isi),1,'last')):end) = isi(find(~isnan(isi),1,'last')-1);
isi = filtfilt(ones(1,h)/h,1,isi); clear t_closest_spike t_prev_spike t_next_spike



waitbar(0.8,wb,'Filtering...');
% filter the envelopes in a time-dependant manner
upper_envelope2 = upper_envelope;
lower_envelope2 = lower_envelope;
scaling_factor = 2;
for i = loc
	if isi(i) < mean_isi
		before = floor(max([1 i-isi(i)*scaling_factor]));
		after = floor(min([length(isi) i+isi(i)*scaling_factor]));
		upper_envelope2(i) = max(upper_envelope(before:after));
		lower_envelope2(i) = min(lower_envelope(before:after));
	else
		% when firing is low, look far enough to see at least two different types of spikes
		[~,idx]=sort(abs(loc-i)); idx(1) = []; % remove itself
		amp_scale = [0 0 0]; j = 1;
		while max(amp_scale(2:3)) == 0 
			this_amp = R(idx(j));
			[~,category]=min(abs(((R(loc==i)/this_amp)) - [1 .5 2]));
			amp_scale(category) = amp_scale(category) + 1;
			j = j + 1;
		end
		if amp_scale(2)
			% there exists a nearby spike that is twice as big as this
			% set the envelope to that spike's envelope
			upper_envelope2(i) = upper_envelope(loc(idx(j-1)));
			lower_envelope2(i) = lower_envelope(loc(idx(j-1)));
		elseif amp_scale(3)
			% there exists a nearby spike that is half as big
			% so we do nothing
		end
		
	end

end
clear upper_envelope lower_envelope
envelope_amplitude = upper_envelope2- lower_envelope2;

%R = R./envelope_amplitude(loc);
close(wb)


% cla(ax2)
% plot(time(loc),R)

% cla(ax2)
% plot(ax2,time(loc),R)

