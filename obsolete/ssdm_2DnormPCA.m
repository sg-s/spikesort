% ssdm_normV
% 
% created by Srinivas Gorur-Shandilya at 3:27 , 15 April 2015. Contact me at http://srinivas.gs/contact/
% 
% This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. 
% To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.

function R = ssdm_2DnormPCA(V_snippets)
for i = 1:size(V_snippets,2)
	V_snippets(:,i) = V_snippets(:,i)/min(V_snippets(:,i));
end
[~,R]=princomp(V_snippets');
R = R(:,1:2)';
