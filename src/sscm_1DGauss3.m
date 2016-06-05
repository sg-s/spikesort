% sscm_1DGauss3.m
% this is a cluster plugin for spikesort.m
% this clustering method splits a 1-dimensional dataset into two assuming that they result from three gaussians
% created by Srinivas Gorur-Shandilya at 10:20 , 09 April 2014. Contact me at http://srinivas.gs/contact/
% 
% This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. 
% To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
function [A,B,N] = sscm_1DGauss3(R,loc)

[y,x] = hist(R,floor(length(R)/30));
if length(x) < 6
	[y,x] = hist(R,floor(length(R)/(floor(length(R)/6))));
end
y = y(:); x = x(:);
y = y/sum(y);
temp = fit(x,y,'gauss3'); % split into two groups
g1=temp.a1.*exp(-((x-temp.b1)./temp.c1).^2);
g2=temp.a2.*exp(-((x-temp.b2)./temp.c2).^2);
g3=temp.a3.*exp(-((x-temp.b3)./temp.c3).^2);

keyboard