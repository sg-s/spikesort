% filter_trace.m 
% part of spikesort.m
%  
% created by Srinivas Gorur-Shandilya at 10:20 , 09 April 2014. Contact me at http://srinivas.gs/contact/
% 
% This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. 
% To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
function [V, Vf] = filter_trace(V)
    if any(isnan(V))
        % filter ignoring NaNs
        Vf = V;
        Vf(~isnan(V)) = filtfilt(ones(1,100)/100,1,V(~isnan(V)));
    else
        Vf = filtfilt(ones(1,100)/100,1,V);
    end
    
    V = V - Vf;
end