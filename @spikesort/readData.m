function [] = readData(s,~,~)

if s.verbosity > 5
    cprintf('green','\n[INFO] ')
    cprintf('text',[mfilename ' called'])
end

% reset some pushbuttons and other things
s.clearCurrentData;

% OK, user has made some selection. let's figure out which plugin to use to load the data
[~,~,chosen_data_ext] = fileparts(s.file_name);
chosen_data_ext(1) =  [];


% then do some post-load stuff, like loading the first trace so that we see something when we load the file
plugin_to_use = find(strcmp('read-data',{s.installed_plugins.plugin_type}).*(strcmp(chosen_data_ext,{s.installed_plugins.data_extension})));
assert(~isempty(plugin_to_use),'[ERR 42] Could not figure out how to read data from file.')
assert(length(plugin_to_use) == 1,'[ERR 43] Too many plugins bound to this file type. ')

if s.verbosity 
	cprintf('green','\n[INFO] ')
	cprintf(['Using plugin: ' s.installed_plugins(plugin_to_use).name])
end


eval(['read_data_handle = @s.' s.installed_plugins(plugin_to_use).name ';'])
read_data_handle();


if isempty(s.raw_voltage)
	return
end

% ok, now that we've read the data using the plugin, update the bounds of the spike detection to something more reasonable (but only do this if we are in auto mode)
if s.handles.prom_auto_control.Value
	if s.filter_trace
		set(s.handles.spike_prom_slider,'Max',3*std(s.filtered_voltage),'Value',std(s.filtered_voltage)/2)
		set(s.handles.prom_ub_control,'String',mat2str(std(s.filtered_voltage)))
	else
		set(s.handles.spike_prom_slider,'Max',std(s.raw_voltage))
		set(s.handles.prom_ub_control,'String',mat2str(std(s.raw_voltage)),'Value',std(s.raw_voltage)/2)
	end
end

% find spikes 
s.findSpikes;
