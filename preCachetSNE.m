% preCachetSNE.m
% this function attempts to pre-calculate t-SNE embeddings for all the data, so that the actual process of spike sorting is faster and less annoying
% 
% usage:
% cd /folder/with/data/from/kontroller
% preCachetSNE('invert_V',true,'variable_name','voltage')
% created by Srinivas Gorur-Shandilya at 9:35 , 11 September 2015. Contact me at http://srinivas.gs/contact/
% 
% This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. 
% To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.

function [] = preCachetSNE()

variable_name = 'voltage';

% use pref.m to change how this function behaves.
pref = readPref;

% add src to path
% add src folder to path
addpath([fileparts(which(mfilename)) oss 'src'])


allfiles = dir('*.mat');

for i = 1:length(allfiles)
	thisfile = allfiles(i).name;
	if ~strcmp(thisfile,'consolidated_data.mat') && ~strcmp(thisfile,'cached.mat')
		load(thisfile)
		for j = 1:length(data)
			if eval(['~isempty(data(j).' variable_name ')'])
				this_data = eval(['(data(j).' variable_name ')']);
				for k = 1:width(this_data)
					try
						
						lc = 1/pref.band_pass(1);
			            lc = floor(lc/pref.deltat);
			            hc = 1/pref.band_pass(2);
			            hc = floor(hc/pref.deltat);
			            V = bandPass(this_data(k,:),lc,hc);

			            % find spikes
						loc = findSpikes(V);

						% take snippets for each putative spike
				        
				        V_snippets = NaN(pref.t_before+pref.t_after,length(loc));
				        for l = 2:length(loc)-1
				            V_snippets(:,l) = V(loc(l)-pref.t_before+1:loc(l)+pref.t_after);
				        end
				        V_snippets(:,1) = []; 
 						V_snippets(:,end) = [];

				        disp(length(V_snippets))
					    % run the fast tSNE algorithm on this
					    fast_tsne(V_snippets,2,10,60);
					catch err
						disp(err)
					end
				end
			end
		end
	end
end
