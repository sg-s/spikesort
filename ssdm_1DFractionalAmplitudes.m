% ssdm_1DFractionalAmplitudes.m
% 
% this is a plugin for spikesort.m
% reduces spikes to a amplitude, measured from the minimum to preceding maximum.
% 
% created by Srinivas Gorur-Shandilya at 10:20 , 09 April 2014. Contact me at http://srinivas.gs/contact/
% 
% This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. 
% To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
function R = ssdm_1DFractionalAmplitudes(V,Vf,deltat,loc)
h = (40*1e-4)/deltat; % deltat in seconds
% 1D - find total spike amplitude for each
R = zeros*loc;
loc_max = 0*loc;
for i = 1:length(loc)
    [R(i),loc_max(i)] = max(V(loc(i)-h:loc(i)) - V(loc(i)));
end
loc_max = loc + loc_max - h;

figure, hold on
plot(time,V)
scatter(time(loc_max),V(loc_max))

% build an upper and lower envelope
upper_envelope = interp1(time(loc_max),V(loc_max),time);
lower_envelope = interp1(time(loc),V(loc),time);

% build a filter timescale
