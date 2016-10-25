% ssdm_2DtSNE.m
% 
% created by Srinivas Gorur-Shandilya at 2:04 , 02 September 2015. Contact me at http://srinivas.gs/contact/
% 
% This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. 
% To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.

function R = ssdm_2DtSNE(V_snippets)

% some parameters
no_dims = 2;
init_dims = 10;
perplexity = 60;

% always use the fast tSNE algorith, as it is internally cached
disp(['hash of V_snippets is ' dataHash(V_snippets)])
R = fast_tsne(V_snippets, no_dims, init_dims, perplexity,.5)';
