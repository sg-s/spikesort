% sscm_1Dkmeans3.m
% this is a cluster plugin for spikesort.m
% this clustering method splits a 1-dimensional dataset into three using k-means
% 
% created by Srinivas Gorur-Shandilya at 10:20 , 09 April 2014. Contact me at http://srinivas.gs/contact/
% 
% This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. 
% To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
function [A,B,N] = sscm_1Dkmeans3(R,loc)

idx=kmeans(R(:),3);

cluster_means = zeros(3,1);
for i = 1:3
	cluster_means(i) = mean(R(idx==i));
end

[~,neuron_order] = sort(cluster_means,'ascend')

N = loc(idx==neuron_order(1));
B = loc(idx==neuron_order(2));
A = loc(idx==neuron_order(3));
