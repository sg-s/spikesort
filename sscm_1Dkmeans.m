% sscm_1Dkmeans.m
% this is a cluster plugin for spikesort.m
% this clustering method splits a 1-dimensional dataset into two assuming that they result from two gaussians
% created by Srinivas Gorur-Shandilya at 10:20 , 09 April 2014. Contact me at http://srinivas.gs/contact/
% 
% This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. 
% To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
function [A,B] = sscm_1Dkmeans(R,loc)


idx=kmeans(R(:),2);
if mean(R(idx==1)) > mean(R(idx==2))
	A=loc(idx==1); B = loc(idx==2);
else
	B=loc(idx==1); A = loc(idx==2);
end

