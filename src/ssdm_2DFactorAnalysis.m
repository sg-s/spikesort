% ssdm_2DFactorAnalysis.m
% Dimensionality reduction plug-in for spikesort: 2D Factor Analysis
% 
% 
% created by Srinivas Gorur-Shandilya at 10:20 , 09 April 2014. Contact me at http://srinivas.gs/contact/
% 
% This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. 
% To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
function R = ssdm_2DFactorAnalysis(V_snippets)
[~,~,~,~,R] = factoran(V_snippets',2);
R =R';