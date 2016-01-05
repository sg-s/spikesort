% consolidateData2.m
% consolidate data accepts a path, and merges all the .mat files there into one consolidate blob
% it makes many assumptions on how the data should be: it should be a Kontroller format
% and should have PID, voltage.
% this is not very general purpose, but hopefully will become more hardened to edge cases as time progresses
% 
% created by Srinivas Gorur-Shandilya at 11:09 , 06 July 2015. Contact me at http://srinivas.gs/contact/
% 
% This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. 
% To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.

function [consolidated_data,all_control_paradigms] = consolidateData2(pathname,use_cache)

if ~nargin
	pathname = pwd;
end
if nargin < 2
	use_cache = false;
end

if ~strcmp(pathname(end),oss)
	pathname = [pathname oss];
end

allfiles = dir([pathname '*.mat']);
% remove the consolidated data from this
rm_this = [find(strcmp('cached_log.mat',{allfiles.name})) find(strcmp('consolidated_data.mat',{allfiles.name})) find(strcmp('cached.mat',{allfiles.name}))];
if ~isempty(rm_this)
	allfiles(rm_this) = [];
end

% always be caching. 
if use_cache
	cached_data = [];
	try
		cached_data = load([pathname 'consolidated_data.mat'],'cached_data');
	catch
	end
	if ~isempty(cached_data)
		output_data = cached_data.output_data;
		all_control_paradigms = cached_data.all_control_paradigms;
		return
	end
end

% make placeholders for all_control_paradigms
all_control_paradigms = struct;
all_control_paradigms.Name = '';
all_control_paradigms.Outputs = [];
all_control_paradigms(1) = [];


% find the longest trial in all the data. this will be the length of the combined data
disp('Determining longest data length...')
ll = 0;
all_variable_names = {};
for i = 1:length(allfiles)
	load(strcat(pathname,allfiles(i).name));
	% get all variable names
	all_variable_names = [all_variable_names; fieldnames(data)];
	for j = 1:length(data)
		if ~isempty(data(j).PID)
			ll = max([ll length(data(j).PID)]);
		end
	end
end
disp('Longest trial observed is:')
disp(ll)

disp('The following variables were observed, and I will attempt to merge these:')
all_variable_names = unique(all_variable_names);
disp(all_variable_names);

% make placeholders for output_data based on observed variable names
for i = 1:length(all_variable_names)
	eval(['output_data.' all_variable_names{i} '=zeros(ll,0);'])
end
% don't forget about the spiking
output_data.fA = zeros(ll,0);
all_variable_names = [all_variable_names; 'fA'];

for i = 1:length(allfiles)
	clear spikes data ControlParadigm SamplingRate
	load(strcat(pathname,allfiles(i).name));
	disp(strcat(pathname,allfiles(i).name));
	for j = 1:length(data)
		textbar(j,length(data))
		for k = 1:size(data(j).PID,1)
			for v = 1:length(all_variable_names)
				load_this = [];
				eval(['load_this = data(j).' all_variable_names{v}, '(k,:);']);
			end
		end
	end
end