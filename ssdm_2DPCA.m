% ssdm_2DPCA.m
% 
% this is a plugin for spikesort.m
% reduces spikes to a amplitude, measured from the minimum to preceding maximum.
% 
% created by Srinivas Gorur-Shandilya at 10:20 , 09 April 2014. Contact me at http://srinivas.gs/contact/
% 
% This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. 
% To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
function R = ssdm_2DPCA(V,deltat,loc)
h = (20*1e4)/deltat; % deltat in seconds
% 1D - find total spike amplitude for each
spike_amplitude = zeros*loc;
for i = 1:length(loc)
    spike_amplitude(i) = max(V(loc(i)-h:loc(i))) - V(loc(i));
end
R = spike_amplitude;	