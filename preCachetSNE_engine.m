% preCachetSNE_engine.m
% this function attempts to pre-calculate t-SNE embeddings for all the data, so that the actual process of spike sorting is faster and less annoying
% 
% usage:
% cd /folder/with/data/from/kontroller
% preCachetSNE('invert_V',true,'variable_name','voltage')
% created by Srinivas Gorur-Shandilya at 9:35 , 11 September 2015. Contact me at http://srinivas.gs/contact/
% 
% This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. 
% To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.

function [] = preCachetSNE_engine()

variable_name = 'voltage';

% use pref.m to change how this function behaves.

pref = readPref(fileparts(which(mfilename)));
dbm = ['The hash of the pref. file I read is ' dataHash(pref)];
system(['echo "' dbm '" >> spikesort.log']);

% add src to path
% add src folder to path
addpath([fileparts(which(mfilename)) oss 'src'])


allfiles = dir('*.mat');

for i = 1:length(allfiles)
	thisfile = allfiles(i).name;
	dbm = ['Working on: ' thisfile];
	system(['echo "' dbm '" >> spikesort.log']);
	if ~strcmp(thisfile,'consolidated_data.mat') && ~strcmp(thisfile,'cached.mat') && ~strcmp(thisfile,'cached_log.mat')
		load(thisfile)
		for j = 1:length(data)
			this_control = ControlParadigm(j).Outputs;
			if eval(['~isempty(data(j).' variable_name ')'])
				this_data = eval(['(data(j).' variable_name ')']);

				for k = 1:width(this_data)
					try
						V = this_data(k,:);

						% use templates to remove artifacts
						if exist([pwd oss 'template.mat'],'file')
							disp('Template exists...')
							if pref.use_on_template || pref.use_off_template
								V = removeArtifactsUsingTemplate(V,this_control,pref);
							end
						end
						

						lc = 1/pref.band_pass(1);
			            lc = floor(lc/pref.deltat);
			            hc = 1/pref.band_pass(2);
			            hc = floor(hc/pref.deltat);
			            
			           	if pref.useFastBandPass
			                [V,Vf] = fastBandPass(V,lc,hc);
			            else
			                [V,Vf] = bandPass(V,lc,hc);
			            end

			            % find spikes
						loc = findSpikes(V);

						% take snippets for each putative spike
				        V_snippets = NaN(pref.t_before+pref.t_after,length(loc));
				        if loc(1) < pref.t_before+1
				            loc(1) = [];
				            V_snippets(:,1) = []; 
				        end
				        if loc(end) + pref.t_after+1 > length(V)
				            loc(end) = [];
				            V_snippets(:,end) = [];
				        end
				        for l = 1:length(loc)
				            V_snippets(:,l) = V(loc(l)-pref.t_before+1:loc(l)+pref.t_after);
				        end

				        if pref.ssDebug
				        	disp('We have these many V_snippets')
				        	disp(length(V_snippets))
				        end

				        if exist('fast_tsne','file')	
						    % run the fast tSNE algorithm on this
						    dbm = ['starting fast_tsne @ ' datestr(now) '.working on paradigm: ' oval(j) ' , trial: ' oval(k)];
							system(['echo "' dbm '" >> spikesort.log']);
							dbm = ['The hash of this data is: ' dataHash(V_snippets)];
							system(['echo "' dbm '" >> spikesort.log']);
						    fast_tsne(V_snippets,2,10,60,.5);
						else
							error('You need bhtsne to use this.')
						end
					catch err
						disp(err)
					end
				end
			end
		end
	end
end
