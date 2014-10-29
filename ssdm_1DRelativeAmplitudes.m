% ssdm_1DRelativeAmplitudes.m
% 
% this is a plugin for spikesort.m
% reduces spikes to a amplitude, measured from the minimum to preceding maximum.
% part of the spikesort package
% https://github.com/sg-s/spikesort
% created by Srinivas Gorur-Shandilya at 10:20 , 09 April 2014. Contact me at http://srinivas.gs/contact/
% 
% This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. 
% To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
function R = ssdm_1DRelativeAmplitudes(V,deltat,loc,ax,ax2)

wb = waitbar(0.2,'Computing Fractional amplitudes...');

h = (40*1e-4)/deltat; % deltat in seconds
% 1D - find total spike amplitude for each
R = zeros*loc;
loc_max = 0*loc;
[R(1),loc_max(1)] = max(V(loc(1)-h:loc(1)) - V(loc(1)));
loc_max(1) = loc(1) + loc_max(1) - h;
for i = 2:length(loc)
	before = max([loc(i)-h loc(i-1)]);
    [R(i),loc_max(i)] = max(V(before:loc(i)) - V(loc(i)));
    loc_max(i) = loc_max(i) + before;
end


waitbar(0.4,wb,'Estimating spike density...');
% build a time-varying estimate of ISI
t_prev_spike = [0 diff(loc)];
t_next_spike = [diff(loc) 0];
t_closest_spike = (t_next_spike + t_prev_spike)/2;
t_closest_spike(1) = t_next_spike(1);
t_closest_spike(end) = t_prev_spike(end);
mean_isi = mean(t_closest_spike); std_isi = std(t_closest_spike);
isi = t_closest_spike; f = 1./isi; f = f/deltat;


waitbar(0.4,wb,'Calculating relative heights...');
time = deltat:deltat:(deltat*length(V));
R2=R;
for i = loc

	if f(loc==i) < 100
		% moderate spiking
		[~,idx]=sort(abs(loc-i)); idx(1) = []; % remove itself
		amp_scale = [0 0 0]; j = 0;
		while max(amp_scale) < 5
			j = j + 1; 
			this_amp = R(idx(j));
			[~,category]=min(abs(((R(loc==i)/this_amp)) - [1 .5 2]));
			amp_scale(category) = amp_scale(category) + 1;
			
		end
		if max(amp_scale(2:3))
			% we see some spike of a different height
			R2(loc==i) = (amp_scale(3)-amp_scale(2))/(sum(amp_scale(2:3)));
		else
			% all the spikes we see are the same height
			% default to assigning it to the last seen
			if find(loc==i) > 1
				R2(loc==i)=R2(find(loc==i)-1);
			else
				% no idea what to do.
				% randomly pick one
				if rand > .5
					R2(loc==i) = 1; 
				else
					R2(loc==i) = -1; 
				end
			end
		end
	else
		% intense spiking. assume A spike, and only check if it is B
		R2(loc==i) = 1;
		
		% find the up to 3 closest spikes that are in the same regime
		[~,idx]=sort(abs(loc-i)); idx(1) = []; % remove itself

		compare_to_these = find(f(idx)>.8*f(loc==i));
		m = min([5 length(compare_to_these)]);
		comparable_r = R(idx(compare_to_these(1:m)));

		if  mean(abs(R(loc==i)./comparable_r-1)) >  mean(abs(R(loc==i)./comparable_r-2))
			% it's a B
			R2(loc==i) = -1;
		end

	end
	
end
close(wb)
R = R2;