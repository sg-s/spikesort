% mergeData.m
% merges data from different files into one file
% use this wisely 
% this will only merge the following variables:
% 
% data
% spikes
% 
% WARNING: NOTHING ELSE WILL BE MERGED.
% 
% created by Srinivas Gorur-Shandilya at 7:57 , 24 June 2015. Contact me at http://srinivas.gs/contact/
% 
% This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. 
% To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.

function [] = mergeData()

allfiles = dir('*.mat');
if length(allfiles) < 2
	error('WTF am I supposed to merge?')
elseif length(allfiles) > 10
	error('Are you sure?')
end

disp('Merging the following files:')
disp({allfiles.name}')
% load the first one to get a sense of what this is like
load(allfiles(1).name)

% reorder fields because of MATLAB stupidity 
data = orderfields(data);
ControlParadigm = orderfields(ControlParadigm);

hash = DataHash(ControlParadigm);

merged_data = data;
merged_spikes = spikes;
merged_ControlParadigm = ControlParadigm;

for i = 2:length(allfiles)
	load(allfiles(i).name)

	data = orderfields(data);
	ControlParadigm = orderfields(ControlParadigm);

	if ~strcmp(DataHash(fieldnames(data)),DataHash(fieldnames(merged_data)))
		error('data that I just loaded has variables that I did not expect.')
	end

	if ~strcmp(DataHash(fieldnames(spikes)),DataHash(fieldnames(merged_spikes)))
		warning('spikes that I just loaded has variables that I did not expect.')
	end

	if strcmp(hash,DataHash(ControlParadigm))
		haz_data = find(Kontroller_ntrials(data));
		for j = haz_data
			if j > length(merged_data)
				error('not coded #39')
			else
				% merge data
				fn = fieldnames(data);
				for k = 1:length(fn)
					eval(strcat('merged_data(j).',fn{k},'= [merged_data(j).',fn{k} ,' ; data(j).',fn{k},'];'))
				end

				% merge spikes
				fn = fieldnames(spikes);
				for k = 1:length(fn)
					eval(strcat('merged_spikes(j).',fn{k},'= [merged_spikes(j).',fn{k} ,' ; spikes(j).',fn{k},'];'))
				end

			end
		end
	else
		% need to match paradigm by paradigm, and make up new ones if needed. 
		disp('ControlParadigm mismatch. Attempting to fit as best as I can...')
		haz_data = find(Kontroller_ntrials(data));
		for j = haz_data
			this_hash = DataHash(ControlParadigm(j));

			% check if this belongs somewhere in the merged master
			m = [];
			for k = 1:length(merged_ControlParadigm)
				if strcmp(DataHash(merged_ControlParadigm(k)),this_hash)
					m = k;
					disp('Matched')
					disp(ControlParadigm(j).Name)
					disp('to:')
					disp(merged_ControlParadigm(k).Name)
				end
			end



			if isempty(m)
				disp('Looks like a new paradigm...')
				merged_ControlParadigm(end+1) = ControlParadigm(j);
				m = length(merged_ControlParadigm);
			end
			
			% merge data
			fn = fieldnames(data);
			if m > length(merged_data) 
				for k = 1:length(fn)
					eval((strcat('merged_data(m).',fn{k},'=  data(j).',fn{k},';')))
				end
			else
				for k = 1:length(fn)
					eval(strcat('merged_data(m).',fn{k},'= [merged_data(m).',fn{k} ,' ; data(j).',fn{k},'];'))
				end
			end

			% merge spikes
			fn = fieldnames(spikes);
			if m > length(merged_spikes) 
				for k = 1:length(fn)
					try
						eval((strcat('merged_spikes(m).',fn{k},'=  spikes(j).',fn{k},';')))
					catch
						warning('Could not merge spikes...')
					end
				end
			else
				for k = 1:length(fn)
					eval(strcat('merged_spikes(m).',fn{k},'= [merged_spikes(m).',fn{k} ,' ; spikes(j).',fn{k},'];'))
				end
			end

			
		end

	end

end

data = merged_data;
spikes = merged_spikes;
ControlParadigm = merged_ControlParadigm;

save('merged_data.mat','ControlParadigm','data','spikes','timestamps','metadata','SamplingRate','OutputChannelNames')