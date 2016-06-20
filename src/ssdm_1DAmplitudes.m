% ssdm_1DAmplitudes.m
% Dimensionality Reduction Plugin for spikesort: 1D spike amplitudes
% 
% this is a plugin for spikesort.m
% reduces spikes to a amplitude, measured from the minimum to preceding maximum.
% 
% created by Srinivas Gorur-Shandilya at 10:20 , 09 April 2014. Contact me at http://srinivas.gs/contact/
% 
% This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. 
% To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
function R = ssdm_1DAmplitudes(V,loc)

pref = readPref;

h = (40*1e-4)/pref.deltat; % deltat in seconds
% 1D - find total spike amplitude for each
R = zeros*loc;
loc_max = 0*loc;
for i = 1:length(loc)
	try
		if pref.invert_V
			before = max([loc(i)-h loc(i-1)]);
			[R(i),loc_max(i)] = max(V(before:loc(i)) - V(loc(i)));
			loc_max(i) = loc_max(i) + before;
		else
			after = min([length(V) loc(i)+h]);
			[R(i),loc_max(i)] =  max(V(loc(i)) - V(loc(i):after));
		end
	catch
	end
end
