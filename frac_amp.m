% frac_amp.m
% returns a vector of fractional amplitudes of spikes given a matrix of voltage snippets around a vector of spike times
% usage:
% R = frac_amp(V_snippets,zero_loc,loc);
%
% meant to be used with spikesort.m
%
% created by Srinivas Gorur-Shandilya at 10:20 , 09 April 2014. Contact me at http://srinivas.gs/contact/
% 
% This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. 
% To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
function R = frac_amp(V_snippets,zero_loc,loc)

% find amplitudes
spike_amplitude = zeros*loc;
for i = 1:length(loc)
    spike_amplitude(i) = max(V_snippets(1:zero_loc-1,i) - V_snippets(zero_loc,i));
end