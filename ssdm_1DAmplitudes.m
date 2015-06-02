% ssdm_1DAmplitudes.m
% 
% this is a plugin for spikesort.m
% reduces spikes to a amplitude, measured from the minimum to preceding maximum.
% 
% created by Srinivas Gorur-Shandilya at 10:20 , 09 April 2014. Contact me at http://srinivas.gs/contact/
% 
% This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. 
% To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
function R = ssdm_1DAmplitudes(V,deltat,loc)
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
