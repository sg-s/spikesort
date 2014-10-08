% sscm_1DGaussianFit.m
% this is a cluster plugin for spikesort.m
% this clustering method splits a 1-dimensional dataset into two assuming that they result from two gaussians
% created by Srinivas Gorur-Shandilya at 10:20 , 09 April 2014. Contact me at http://srinivas.gs/contact/
% 
% This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. 
% To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
function [A,B] = sscm_1DGaussianFit(R,loc)

[y,x] = hist(R,floor(length(R)/30));
temp = fit(x(:),y(:),'gauss2'); % split into two groups
g1=temp.a1.*exp(-((x-temp.b1)./temp.c1).^2);
g2=temp.a2.*exp(-((x-temp.b2)./temp.c2).^2);
if temp.b1 > temp.b2
    cutoff=find((g2-g1)>0,1,'last');
    cutoff = x(cutoff);
else
    cutoff=find((g1-g2)>0,1,'last');
    cutoff = x(cutoff);

end

% mark as A or B
B = loc(R<cutoff);
A = loc(R>=cutoff);
