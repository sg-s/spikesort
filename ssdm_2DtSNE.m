% ssdm_2DtSNE.m
% 
% created by Srinivas Gorur-Shandilya at 2:04 , 02 September 2015. Contact me at http://srinivas.gs/contact/
% 
% This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. 
% To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.

function R = ssdm_2DtSNE(V_snippets)

V_snippets = V_snippets';


% some parameters
no_dims = 2;
init_dims = 10;
perplexity = 60;

labels = ones(size(V_snippets,1),1);

% based on size of data, use vanilla t-SNE or Barnes-Hut version
if size(V_snippets,1) > 1200
	R = fast_tsne(V_snippets, no_dims, init_dims, perplexity,.5)';
else
	h = figure('Name','t-SNE visualisation','toolbar','None','Menubar','none','NumberTitle','off');
	R = tsne(V_snippets, labels, no_dims, init_dims, perplexity,h)';
end
