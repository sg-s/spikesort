% ssdm_2DtSNE.m
% 
% created by Srinivas Gorur-Shandilya at 2:04 , 02 September 2015. Contact me at http://srinivas.gs/contact/
% 
% This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. 
% To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.

function R = ssdm_2DtSNE(V_snippets)

V_snippets = V_snippets';

h = figure('Name','t-SNE visualisation','toolbar','None','Menubar','none','NumberTitle','off');

% some parameters
no_dims = 2;
init_dims = 30;
perplexity = 30;
labels = ones(size(V_snippets,1),1);

R = tsne(V_snippets, labels, no_dims, init_dims, perplexity,h);
