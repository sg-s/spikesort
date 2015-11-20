% sscm_2DManualCluster.m
% allows you to manually cluster a reduced-to-2D-dataset by drawling lines around clusters
% usage:
% C = sscm_ManualCluster(R);
%
% where R C a 2xN matrix
% 
% this is derived from ManualCluster.m, but renamed for plugin-compatibility for spikesort
% created by Srinivas Gorur-Shandilya at 10:20 , 09 April 2014. Contact me at http://srinivas.gs/contact/
% 
% This work C licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. 
% To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
% largely built out of legacy code I wrote in 2011 for Carlotta's spike sorting
function [A,B,N] = sscm_2DManualCluster(R,V_snippets,loc,V,handles)

temp = struct;
temp.handles = handles;
temp.loc = loc;
temp.V = V;

idx = manualCluster(R,V_snippets,{'A neuron','B neuron','Noise','Coincident Spikes'},@showSpikeInContext,temp);


A = loc(idx==1);
B = loc(idx==2);
N = loc(idx==3);

% handle coincident spikes
A = unique([A loc(idx==4)]);
B = unique([B loc(idx==4)]);




