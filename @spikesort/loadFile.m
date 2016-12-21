% callback function when you press "load file" in the GUI

function s = loadFile(s,src,~)

if s.verbosity > 5
    cprintf('green','\n[INFO] ')
    cprintf('text',[mfilename ' called'])
end

% reset some pushbuttons and other things
s.clearCurrentData;

% figure out what file types we can work with
allowed_file_extensions = setdiff(unique({s.installed_plugins.data_extension}),'n/a');
allowed_file_extensions = cellfun(@(x) ['*.' x], allowed_file_extensions,'UniformOutput',false);


if strcmp(get(src,'String'),'Load File')
    [s.file_name,s.path_name,filter_index] = uigetfile(allowed_file_extensions);
    if ~s.file_name
        return
    end
elseif strcmp(get(src,'String'),'<')
    if isempty(s.file_name)
        return
    else
        s.saveData;

        s.this_trial = [];
        s.this_paradigm = [];
        
        % get the list of files
        [~,~,ext]=fileparts(s.file_name);
        allfiles = dir([s.path_name '*' ext]);
        % remove hidden files that begin with a ".
        allfiles(cellfun(@(x) strcmp(x(1),'.'),{allfiles.name})) = [];
        % permute the list so that the current file is last
        allfiles = circshift({allfiles.name},[0,length(allfiles)-find(strcmp(s.file_name,{allfiles.name}))])';
        % pick the previous one 
        s.file_name = allfiles{end-1};
        % figure out what the filter_index is
        filter_index = find(strcmp(['*' ext],allowed_file_extensions));
        
    end
else
    if isempty(s.file_name)
        return
    else
        s.saveData;

        s.this_trial = [];
        s.this_paradigm = [];

        % get the list of files
        [~,~,ext]=fileparts(s.file_name);
        allfiles = dir([s.path_name '*' ext]);
        % remove hidden files that begin with a ".
        allfiles(cellfun(@(x) strcmp(x(1),'.'),{allfiles.name})) = [];
        % permute the list so that the current file is last
        allfiles = circshift({allfiles.name},[0,length(allfiles)-find(strcmp(s.file_name,{allfiles.name}))])';
        % pick the first one 
        s.file_name = allfiles{1};
        % figure out what the filter_index is
        filter_index = find(strcmp(['*' ext],allowed_file_extensions));
        
    end
end

% OK, user has made some selection. let's figure out which plugin to use to load the data
chosen_data_ext = strrep(allowed_file_extensions{filter_index},'*.','');
plugin_to_use = find(strcmp('load-file',{s.installed_plugins.plugin_type}).*(strcmp(chosen_data_ext,{s.installed_plugins.data_extension})));
assert(~isempty(plugin_to_use),'[ERR 40] Could not figure out how to load the file you chose.')
assert(length(plugin_to_use) == 1,'[ERR 41] Too many plugins bound to this file type. ')

% load the file
eval(['file_load_handle = @s.' s.installed_plugins(plugin_to_use).name ';'])
file_load_handle();

% update the titlebar with the name of the file we are working with
s.handles.main_fig.Name = s.file_name;

% enable all controls
set(s.handles.method_control,'Enable','on')
set(s.handles.sine_control,'Enable','on');
set(s.handles.autosort_control,'Enable','on');
set(s.handles.redo_control,'Enable','on');
set(s.handles.filtermode,'Enable','on');
set(s.handles.cluster_control,'Enable','on');
set(s.handles.trial_chooser,'Enable','on');
set(s.handles.paradigm_chooser,'Enable','on');
set(s.handles.discard_control,'Enable','on');
set(s.handles.metadata_text_control,'Enable','on')


    
% check to see if this file is tagged. 
if ismac
    clear es
    es{1} = 'tag -l ';
    es{2} = strcat(s.path_name,s.file_name);
    [~,temp] = unix(strjoin(es));
    temp = strrep(temp,[s.path_name s.file_name],'');
    set(s.handles.tag_control,'String',strtrim(temp));
end
