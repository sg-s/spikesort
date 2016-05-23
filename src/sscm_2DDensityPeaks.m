% sscm_2DDensityPeaks.m
% this plugin for spikesort uses the density peaks algorithm to automatically cluster spikes into 3 clusters (noise, B and A)
%
% 
% created by Srinivas Gorur-Shandilya. Contact me at http://srinivas.gs/contact/
% 
function [A,B,N] = sscm_2DDensityPeaks(R,V_snippets,loc)

L = densityPeaks(R,'n_clusters',3,'percent',2);

save('~/Desktop/R.mat','R')

% figure out which label is which
r = zeros(3,1);
for i = 1:3
	r(i) = mean( max(V_snippets(:,L==i)) - min(V_snippets(:,L==i)));
end

A = loc(L == find(r==max(r)));
N = loc(L == find(r==min(r)));
B = loc(L == find(r==median(r)));

pref = readPref;

% if we have to show the final solution, show it
if pref.show_dp_clusters
	temp = figure('Position',[0 0 800 800]); hold on
	c = lines(3);
	for i = 1:3
		plot(R(1,L==i),R(2,L==i),'+','Color',c(i,:))
	end
	prettyFig
	[~,idx]=sort(r,'descend');
	LL = {'A','B','noise'};
	legend(LL(idx))
	pause(3)
	delete(temp)
end