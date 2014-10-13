% filter_envelope.m
% filters the spike amplitude envelope
% part of the spikesort package
% https://github.com/sg-s/spikesort
% 
% created by Srinivas Gorur-Shandilya at 10:20 , 09 April 2014. Contact me at http://srinivas.gs/contact/
% 
% This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. 
% To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
function K = filter_envelope(filter_width,time)
% use an alpha function
t = 1:filter_width;
tau = time;
A = 1;
K = filter_alpha(tau,A,t);
