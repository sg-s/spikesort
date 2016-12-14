function saveData(s)

if s.verbosity > 5
    cprintf('green','\n[INFO] ')
    cprintf('text',[mfilename ' called'])
end

% figure out which plugin to use to save data
[~,~,chosen_data_ext] = fileparts(s.file_name);
chosen_data_ext(1) =  [];

plugin_to_use = find(strcmp('save-data',{s.installed_plugins.plugin_type}).*(strcmp(chosen_data_ext,{s.installed_plugins.data_extension})));
assert(~isempty(plugin_to_use),'[ERR 42] Could not figure out how to save data to file.')
assert(length(plugin_to_use) == 1,'[ERR 43] Too many plugins bound to this file type. ')

eval(['save_data_handle = @s.' s.installed_plugins(plugin_to_use).name ';'])
save_data_handle();

