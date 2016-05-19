% sscm_2DDensityPeaks.m
% this plugin for spikesort uses the density peaks algorithm to automatically cluster spikes into 3 clusters (noise, B and A)
%
% 
% created by Srinivas Gorur-Shandilya. Contact me at http://srinivas.gs/contact/
% 
function [A,B,N] = sscm_2DDensityPeaks(R,V_snippets,loc)

L = densityPeaks(R,'n_clusters',3);

% figure out which label is which
r = zeros(3,1);
for i = 1:3
	r(i) = mean( max(V_snippets(:,L==i)) - min(V_snippets(:,L==i)));
end

A = loc(L == find(r==max(r)));
N = loc(L == find(r==min(r)));
B = loc(L == find(r==median(r)));

